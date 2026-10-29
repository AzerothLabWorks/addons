#!/usr/bin/env python3
"""Exercise the packaged tracker with WoW-compatible Lua 5.1 and read-only data evidence."""

import argparse
import json
from pathlib import Path
import re
import struct
import unittest
from lupa.lua51 import LuaRuntime


ROOT = Path(__file__).resolve().parents[2]
ADDON = ROOT / "CoALfgTracker"
DBC_DIR = None

FIXTURE = r'''
assert(_VERSION == "Lua 5.1")
Now, Map, Difficulty, IsLfg, Kind = 100, 558, 1, true, "party"
Frames, Requests = {}, {}
Names = {}
UNKNOWNOBJECT, DEFEAT_S = "Unknown", "Defeat: %s"
function GetTime() return Now end
function UnitName() return "Thada" end
function GetRealmName() return "COA G1 CANDIDATE" end
function GetActiveMapID() return Map end
function GetInstanceInfo() return "Instance", Kind, Difficulty end
function IsPartyLFG() return IsLfg end
function GetEncounterInfo(id) return Names[id] end
function GetLFGBoss() return 0 end
NativeGetLFGBoss, NativeGetEncounterInfo = GetLFGBoss, GetEncounterInfo
BossObjectiveTrackerMixin = {marker = "shared-untouched"}
ManastormObjectiveTracker = {marker = "manastorm-untouched"}
LFGObjectiveTracker = {bossDefeated = false, objectives = {}}
Objective = {
    SetObjective = function(self, text, current, total)
        self.text, self.current, self.total = text, current, total
    end,
    updateFunc = function(self)
        local bossName = GetEncounterInfo(GetLFGBoss())
        if LFGObjectiveTracker.bossName ~= bossName then LFGObjectiveTracker.bossDefeated = false end
        LFGObjectiveTracker.bossName = bossName
        self:SetObjective(DEFEAT_S:format(bossName or UNKNOWNOBJECT),
            LFGObjectiveTracker.bossDefeated and 1 or 0, 1)
    end,
}
LFGObjectiveTracker.objectives[1] = Objective
function CreateFrame()
    local f = {scripts = {}, events = {}}
    function f:SetScript(event, fn) self.scripts[event] = fn end
    function f:RegisterEvent(event) self.events[event] = true end
    Frames[#Frames + 1] = f
    return f
end
function SendAddonMessage(prefix, payload, channel, target)
    Requests[#Requests + 1] = {prefix, payload, channel, target}
end
function Event(event, ...)
    for _, f in ipairs(Frames) do
        if f.events[event] then f.scripts.OnEvent(f, event, ...) end
    end
end
function Tick(seconds)
    Now = Now + (seconds or 6)
    for _, f in ipairs(Frames) do f.scripts.OnUpdate(f, seconds or 6) end
end
function Nonce()
    return Requests[#Requests][2]:match("^Q|1|(.+)$")
end
function Reply(encounter, done, changes)
    local row = CoALfgTrackerData.encounters[encounter]
    local fields = {"S", "1", Nonce(), row[1], row[2], 57, "225179981368524801",
        row[3], encounter, row[4], row[5], done}
    for index, value in pairs(changes or {}) do fields[index] = value end
    Event("CHAT_MSG_ADDON", "COA_LFG_STATUS", table.concat(fields, "|"), "WHISPER", "Thada")
end
function Same(actual, expected)
    assert(actual == expected, "expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
function StableGlobals()
    Same(GetLFGBoss, NativeGetLFGBoss)
    Same(GetEncounterInfo, NativeGetEncounterInfo)
    Same(BossObjectiveTrackerMixin.marker, "shared-untouched")
    Same(ManastormObjectiveTracker.marker, "manastorm-untouched")
end
'''


class TrackerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if LuaRuntime().eval("_VERSION") != "Lua 5.1":
            raise RuntimeError("The selected interpreter must be Lua 5.1")
        cls.data = (ADDON / "CoALfgTrackerData.lua").read_text(encoding="utf-8")
        cls.code = (ADDON / "CoALfgTracker.lua").read_text(encoding="utf-8")

    def case(self, body, before=""):
        program = FIXTURE + "\n" + before + "\n" + self.data + "\n" + self.code + "\n" + body
        LuaRuntime().execute(program)

    def test_auchenai_name_uses_server_selected_encounter(self):
        self.case('''
Event("PLAYER_ENTERING_WORLD")
Same(Requests[1][1], "COA_LFG_STATUS")
Same(Requests[1][3], "WHISPER"); Same(Requests[1][4], "Thada")
Reply(202, 0)
Same(Objective.text, "Defeat: Exarch Maladaar"); Same(Objective.current, 0)
Tick(); Reply(202, 1); Same(Objective.current, 1)
StableGlobals()
''')

    def test_localized_name_is_preserved(self):
        self.case('''
Names[202] = "Localized Exarch"
Event("PLAYER_ENTERING_WORLD"); Reply(202, 0)
Same(Objective.text, "Defeat: Localized Exarch")
''')

    def test_valid_native_name_is_retained_but_completion_is_authoritative(self):
        self.case('''
Names[202] = "Native Exarch Maladaar"
LFGObjectiveTracker.bossName = Names[202]
LFGObjectiveTracker.bossDefeated = true
Event("PLAYER_ENTERING_WORLD"); Reply(202, 0)
Same(Objective.text, "Defeat: Native Exarch Maladaar"); Same(Objective.current, 0)
Tick(); Reply(202, 1); Same(Objective.current, 1)
StableGlobals()
''', before='''
function GetLFGBoss() return 202 end
NativeGetLFGBoss = GetLFGBoss
''')

    def test_wrong_native_encounter_cannot_override_validated_server_selection(self):
        self.case('''
Names[539] = "Bazil Thredd"
Event("PLAYER_ENTERING_WORLD"); Reply(202, 0)
Same(Objective.text, "Defeat: Exarch Maladaar"); Same(Objective.current, 0)
StableGlobals()
''', before='''
function GetLFGBoss() return 539 end
NativeGetLFGBoss = GetLFGBoss
''')

    def test_normal_heroic_and_wing_maps_have_distinct_records(self):
        self.case('''
local count = 0
for id, row in pairs(CoALfgTrackerData.encounters) do
    count = count + 1
    Map, Difficulty = row[1], row[2] + 1
    Event("PLAYER_ENTERING_WORLD"); Tick(2)
    Reply(id, 0); Same(Objective.current, 0)
    Same(Objective.text, "Defeat: " .. row[6])
    Tick(); Reply(id, 1); Same(Objective.current, 1)
end
Same(count, 131)
StableGlobals()
''')

    def test_death_and_reward_events_do_not_invent_completion(self):
        self.case('''
Event("PLAYER_ENTERING_WORLD"); Reply(202, 0)
LFGObjectiveTracker.bossDefeated = true
Event("COMBAT_LOG_EVENT_UNFILTERED", Now, "UNIT_DIED", "wrong-guid", "Exarch Maladaar")
Objective:updateFunc(); Same(Objective.current, 0)
Event("LFG_COMPLETION_REWARD"); Objective:updateFunc(); Same(Objective.current, 0)
Tick(); Reply(202, 1); Same(Objective.current, 1)
''')

    def test_spell_credit_completion_requires_snapshot(self):
        self.case('''
Map = 595
Event("PLAYER_ENTERING_WORLD"); Reply(296, 0)
Same(Objective.current, 0)
Tick(); Reply(296, 1); Same(Objective.current, 1)
Same(Objective.text, "Defeat: Mal'ganis")
''')

    def test_old_nonce_is_rejected_after_group_or_map_change(self):
        self.case('''
Event("PLAYER_ENTERING_WORLD"); local old = Nonce(); Reply(202, 1)
LFGObjectiveTracker.bossDefeated = true
Event("PARTY_MEMBERS_CHANGED"); Tick(2)
Reply(202, 1, {[3] = old})
Same(Objective.current, 0)
Reply(202, 0, {[7] = "225179981368524802"}); Same(Objective.current, 0)
Tick(); Reply(202, 1); Same(Objective.current, 1)
Map = 34; Event("PLAYER_ENTERING_WORLD"); Tick(2)
Reply(202, 1); Same(Objective.current, 0)
Reply(539, 0); Same(Objective.text, "Defeat: Bazil Thredd")
''')

    def test_snapshot_restores_completion_after_reload(self):
        self.case('''
Event("PLAYER_ENTERING_WORLD")
Same(Objective.current, 0)
Reply(202, 1); Same(Objective.current, 1)
''')

    def test_new_instance_can_be_incomplete_in_same_map(self):
        self.case('''
Event("PLAYER_ENTERING_WORLD"); Reply(202, 1)
Event("PLAYER_ENTERING_WORLD"); Tick(2)
Same(Objective.current, 0)
Reply(202, 0, {[6] = 58}); Same(Objective.current, 0)
''')

    def test_malformed_or_mismatched_responses_cannot_complete(self):
        self.case('''
Event("PLAYER_ENTERING_WORLD"); Reply(202, 0); Tick()
local bad = {
    {[2] = "2"}, {[3] = "unrequested"}, {[4] = 34}, {[5] = 1}, {[6] = 0},
    {[7] = "0"}, {[7] = "18446744073709551616"}, {[7] = "-1"},
    {[8] = 178}, {[9] = 247}, {[10] = 1}, {[11] = 1}, {[12] = 2},
    {[6] = "nan"}, {[6] = "1e3"}, {[6] = "4294967296"},
}
for _, change in ipairs(bad) do Reply(202, 1, change); Same(Objective.current, 0) end
local text = "S|1|" .. Nonce() .. "|558|0|57|225179981368524801|149|202|0|18373|1"
for _, sender in ipairs({"Other", "Thada-WrongRealm"}) do
    Event("CHAT_MSG_ADDON", "COA_LFG_STATUS", text, "WHISPER", sender)
    Same(Objective.current, 0)
end
Event("CHAT_MSG_ADDON", "COA_LFG_STATUS", text, "PARTY", "Thada")
Same(Objective.current, 0)
Event("CHAT_MSG_ADDON", "COA_LFG_STATUS", text .. "|", "WHISPER", "Thada")
Same(Objective.current, 0)
Reply(202, 1); Same(Objective.current, 1)
''')

    def test_expired_response_does_not_complete(self):
        self.case('''
Event("PLAYER_ENTERING_WORLD"); Reply(202, 0); Tick()
Now = Now + 6; Reply(202, 1); Same(Objective.current, 0)
''')

    def test_neutral_reply_preserves_native_classic_path(self):
        self.case('''
Names[539] = "Native Stockades"
LFGObjectiveTracker.bossName = Names[539]
Event("PLAYER_ENTERING_WORLD")
Event("CHAT_MSG_ADDON", "COA_LFG_STATUS", "N|1|" .. Nonce(), "WHISPER", "Thada")
Same(Objective.text, "Defeat: Native Stockades")
Same(Objective.current, 1)
StableGlobals()
''', before='''
Map = 34
function GetLFGBoss() return 539 end
NativeGetLFGBoss = GetLFGBoss
LFGObjectiveTracker.bossDefeated = true
''')

    def test_unsupported_custom_mythic_raid_and_non_lfg_are_untouched(self):
        for before in ("Difficulty=3", "Map=99999", 'Kind="raid"', "IsLfg=false"):
            with self.subTest(before=before):
                self.case('''
Event("PLAYER_ENTERING_WORLD"); Tick(6)
Same(#Requests, 0); Same(Objective.current, 1)
StableGlobals()
''', before=before + "\nLFGObjectiveTracker.bossDefeated=true")

    def test_request_rate_is_bounded_and_empty_payload_ignored(self):
        self.case('''
Event("PLAYER_ENTERING_WORLD")
for i = 1, 100 do
    Event("LFG_COMPLETION_REWARD")
    Event("CHAT_MSG_ADDON", "COA_LFG_STATUS", "", "WHISPER", "Thada")
    Tick(0)
end
Same(#Requests, 1)
Tick(1); Same(#Requests, 1)
Tick(4); Same(#Requests, 2)
''')

    def test_packaged_toc_has_no_saved_completion_state(self):
        toc = (ADDON / "CoALfgTracker.toc").read_text(encoding="utf-8")
        self.assertNotIn("SavedVariables", toc)
        self.assertIn("## Interface: 30300", toc)
        self.assertLess(toc.index("CoALfgTrackerData.lua"), toc.index("CoALfgTracker.lua"))

    def test_packaged_records_match_accepted_dbc(self):
        if DBC_DIR is None:
            self.skipTest("supply --dbc-dir to validate packaged names and mappings against accepted DBCs")
        def read_dbc(name):
            raw = (DBC_DIR / name).read_bytes()
            magic, count, fields, size, strings_size = struct.unpack_from("<4s4I", raw)
            self.assertEqual(magic, b"WDBC")
            self.assertEqual(size, fields * 4)
            self.assertEqual(len(raw), 20 + count * size + strings_size)
            rows = [struct.unpack_from("<" + "I" * fields, raw, 20 + index * size)
                    for index in range(count)]
            return {row[0]: row for row in rows}, raw[20 + count * size:]

        encounters, strings = read_dbc("DungeonEncounter.dbc")
        dungeons, _ = read_dbc("LFGDungeons.dbc")
        rows = re.findall(r'\[(\d+)\] = \{(\d+), (\d+), (\d+), (\d+), (\d+), ("[^"\n]*")\}', self.data)
        self.assertEqual(len(rows), 131)
        self.assertEqual(len({row[0] for row in rows}), len(rows))
        for text_id, text_map, text_difficulty, text_dungeon, _, _, quoted in rows:
            encounter_id, map_id, difficulty, dungeon_id = map(int, (text_id, text_map, text_difficulty, text_dungeon))
            encounter, dungeon = encounters[encounter_id], dungeons[dungeon_id]
            self.assertEqual(encounter[1:3], (map_id, difficulty))
            self.assertEqual(dungeon[23:25], (map_id, difficulty))
            self.assertEqual(dungeon[26], 1)
            self.assertIn(dungeon[29], (0, 1, 2))
            self.assertIn(difficulty, (0, 1))
            actual_name = strings[encounter[5]:].split(b"\0", 1)[0].decode("utf-8")
            self.assertEqual(json.loads(quoted), actual_name)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--dbc-dir", type=Path)
    arguments, remaining = parser.parse_known_args()
    DBC_DIR = arguments.dbc_dir
    unittest.main(argv=[__file__, *remaining])
