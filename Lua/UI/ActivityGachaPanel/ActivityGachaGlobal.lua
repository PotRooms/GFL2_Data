require("UI.UIBasePanel")
ActivityGachaGlobal = {}
ActivityGachaGlobal.GroupState_Doing = 1
ActivityGachaGlobal.GroupState_Close = 2
ActivityGachaGlobal.GroupState_Open = 3
ActivityGachaGlobal.GroupState_NotOpen = 4
ActivityGachaGlobal.ActivityGroupState = CS.ProtoObject.ActivityGroupState
ActivityGachaGlobal.TargteType = NetCmdActivityGachaData.TargteType
ActivityGachaGlobal.NormalType = NetCmdActivityGachaData.NormalType
ActivityGachaGlobal.IconRootPath = "ActivityGacha/"
ActivityGachaGlobal.DaiyanPath = "Daiyan"
ActivityGachaGlobal.LennaPath = "Lenna"
ActivityGachaGlobal.SpriteName = {
  MainBg = "Img_ActivityGacha_Bg",
  GachaGroupIcon = "Img_ActivityGacha_Num",
  TopBg = "Img_ActivityGacha_TitleBg",
  TopFg = "Img_ActivityGacha_TitleLeft",
  GachaOneBg = "Img_ActivityGacha_BtnLeft",
  GachaHl = "Img_ActivityGacha_BtnHL",
  GachaManyBg = "Img_ActivityGacha_BtnRight",
  TurnItemBg = "Img_ActivityGacha_Card",
  TurnItemHl = "Img_ActivityGacha_HL",
  TurnItemSel = "Img_ActivityGacha_Sel",
  TurnBg = "Img_ActivityGacha_TurnBg",
  TextDeco = "Img_ActivityGacha_TextDeco",
  FootBg = "Img_ActivityGacha_AfootBg"
}
ActivityGachaGlobal.TextListColor = {
  [ActivityGachaGlobal.DaiyanPath] = CS.GF2.UI.UITool.StringToColor("1A2C33"),
  [ActivityGachaGlobal.LennaPath] = CS.GF2.UI.UITool.StringToColor("EFEFEF")
}
ActivityGachaGlobal.GachaGroupItemPrefabPath = "ActivityGacha/Btn_ActivitieGachaTurnItem.prefab"
ActivityGachaGlobal.GachaRaffleCountStr = "GachaRaffleCount"
