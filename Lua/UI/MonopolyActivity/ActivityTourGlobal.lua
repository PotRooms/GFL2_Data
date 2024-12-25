require("UI.UIBasePanel")
ActivityTourGlobal = class("ActivityTourGlobal", UIBasePanel)
ActivityTourGlobal.__index = ActivityTourGlobal
ActivityTourGlobal = {}
ActivityTourGlobal.Camp = CS.GF2.Monopoly.Camp.Player
ActivityTourGlobal.MonsterCamp_Int = CS.LuaUtils.EnumToInt(CS.GF2.Monopoly.Camp.Monster)
ActivityTourGlobal.PlayerCamp_Int = CS.LuaUtils.EnumToInt(CS.GF2.Monopoly.Camp.Player)
ActivityTourGlobal.MonopolyFunctionType = CS.GF2.Data.MonopolyFunctionType
ActivityTourGlobal.ActorType = CS.GF2.Monopoly.MonopolyActorDefine.ActorType
ActivityTourGlobal.SelectObjType_None = CS.LuaUtils.EnumToInt(CS.GF2.Monopoly.SelectObjType.None)
ActivityTourGlobal.SelectObjType_Actor = CS.LuaUtils.EnumToInt(CS.GF2.Monopoly.SelectObjType.Actor)
ActivityTourGlobal.SelectObjType_Grid = CS.LuaUtils.EnumToInt(CS.GF2.Monopoly.SelectObjType.Grid)
ActivityTourGlobal.OccupyCampPlayer = CS.LuaUtils.EnumToInt(CS.GF2.Monopoly.Camp.Player)
ActivityTourGlobal.MapGridRowCount = CS.GF2.Monopoly.MonopolyDefine.GridNum
ActivityTourGlobal.EventSelectDialog_UIType = CS.GF2.Monopoly.EventSelectDialog_UIType
ActivityTourGlobal.TreatmentSelectDialog_UIType = CS.GF2.Monopoly.TreatmentSelectDialog_UIType
ActivityTourGlobal.MaxCommandNum = 5
ActivityTourGlobal.MaxBattleReportShowCount = 4
ActivityTourGlobal.MaxBattleReportItemFadeTime = 0.33

function ActivityTourGlobal.SetGlobalValue()
  MpGridManager = CS.GF2.Monopoly.MpGridManager.Instance
  MonopolyWorld = CS.GF2.Monopoly.MonopolyWorld.Instance
  MonopolyUtil = CS.GF2.Monopoly.MonopolyUtil.Instance
  MonopolySelectManager = CS.GF2.Monopoly.MonopolySelectManager.Instance
end

ActivityTourGlobal.NumberTip = 1
ActivityTourGlobal.InspirationTip = 2
ActivityTourGlobal.CommandTip = 3
ActivityTourGlobal.PointPath = "Icon_ActivityTourMove_Point_"
ActivityTourGlobal.EventPointBuffIconPath = "Item_Icon_Activity_Buff"
ActivityTourGlobal.EventPointBuffRare = 2
ActivityTourGlobal.EncounterBgDir = "ActivityTourMap"
ActivityTourGlobal.StoreTabType_Buy = 1
ActivityTourGlobal.StoreTabType_Compose = 2
ActivityTourGlobal.StoreTabType_Bag = 3
ActivityTourGlobal.MinBattleReportHeight = 28
ActivityTourGlobal.DeleteCommandType = {Bag = 0, Get = 1}
ActivityTourGlobal.EnemyInfoType = {
  CommandInfo = 1,
  AttackInfo = 2,
  BuffStateInfo = 3
}
ActivityTourGlobal.CommandType = CS.GF2.Data.OrderType
ActivityTourGlobal.CommandType_RandomMovePoint = CS.LuaUtils.EnumToInt(CS.GF2.Data.OrderType.Random)
ActivityTourGlobal.CommandType_ManualMovePoint = CS.LuaUtils.EnumToInt(CS.GF2.Data.OrderType.Selected)
ActivityTourGlobal.FinishType = CS.ProtoObject.MonopolyRoom.Types.FinishType
ActivityTourGlobal.FinishType_Win = CS.LuaUtils.EnumToInt(CS.ProtoObject.MonopolyRoom.Types.FinishType.Win)
ActivityTourGlobal.FinishType_Lose = CS.LuaUtils.EnumToInt(CS.ProtoObject.MonopolyRoom.Types.FinishType.Lose)
ActivityTourGlobal.RandomRewardType = CS.ProtoObject.RewardRepo.Types.RewardList.Types.RewardType
ActivityTourGlobal.MonopolyDefine = CS.GF2.Monopoly.MonopolyDefine
ActivityTourGlobal.MaxHp = CS.GF2.Monopoly.MonopolyDefine.MaxHp
ActivityTourGlobal.ShowPointType = CS.GF2.Monopoly.MonopolyDefine.ShowPointType
ActivityTourGlobal.ShowDetailType = CS.GF2.Monopoly.ShowDetailType
ActivityTourGlobal.PointChangeReason = CS.ProtoObject.PointChangeReason
ActivityTourGlobal.ButtonBlockTime = CS.GF2.Monopoly.MonopolyDefine.ButtonBlockTime
ActivityTourGlobal.ErrorCodeActivityNotOpenOrClosed = LuaUtils.EnumToInt(CS.ProtoCsmsg.ErrorCode.ActivityNotOpenOrClosed)

function ActivityTourGlobal.GetActivityTourSprite(spriteName)
  return IconUtils.GetAtlasV2("ActivityTour", spriteName)
end

function ActivityTourGlobal.GetCommandItemQualityColor(rank)
  return TableData.GetActivityTourCommand_Quality_Color(rank)
end

function ActivityTourGlobal.ReplaceAllColor(uiRoot)
  CS.GF2.Monopoly.MonopolyDefine.ReplaceAllColor(uiRoot)
end

function ActivityTourGlobal.GetMaxWillValue(gunID)
  local gun = NetCmdTeamData:GetGunByID(gunID)
  if gun == nil then
    return 0
  end
  return gun:GetGunPropertyValueByType(CS.GF2.Data.DevelopProperty.MaxWillValue)
end

function ActivityTourGlobal.GetOrderMoveRange(orderData)
  return CS.GF2.Monopoly.MonopolyDefine.GetOrderMovePoint(orderData)
end

function ActivityTourGlobal.GetPointIcon()
  return IconUtils.GetItemIconSprite(ActivityTourGlobal.PointsId)
end
