require("UI.UIBasePanel")
require("UI.MonopolyActivity.CharInfo.Btn_ActivityTourChrInfoListItem")
UIActivityTourTeamStateDialog = class("UIActivityTourTeamStateDialog", UIBasePanel)
UIActivityTourTeamStateDialog.__index = UIActivityTourTeamStateDialog

function UIActivityTourTeamStateDialog:ctor(csPanel)
  self.super.ctor(self, csPanel)
  csPanel.Type = UIBasePanelType.Dialog
end

function UIActivityTourTeamStateDialog:OnAwake(root, data)
  self:SetRoot(root)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  self:AddBtnListener()
  MonopolyUtil:SetMonopolyActivityUIHint(self.mUIRoot.transform)
end

function UIActivityTourTeamStateDialog:OnInit(root, data)
  self.mUICharItems = {}
  self.mBuffPrefabItem = {}
  ActivityTourGlobal.ReplaceAllColor(self.mUIRoot)
end

function UIActivityTourTeamStateDialog:OnShowStart()
  self:RefreshAllTeamInfo()
  self:RefreshTeamState()
end

function UIActivityTourTeamStateDialog:RefreshAllTeamInfo()
  local teamInfo = MonopolyWorld.MpData.teamInfo
  for i = 1, teamInfo.Count do
    local gunItem = self.mUICharItems[i]
    if not gunItem then
      gunItem = Btn_ActivityTourChrInfoListItem.New()
      gunItem:InitCtrl(self.ui.mSListChild_Content.childItem, self.ui.mSListChild_Content.transform)
      self.mUICharItems[i] = gunItem
    end
    gunItem:SetData(teamInfo[i - 1], false)
  end
end

function UIActivityTourTeamStateDialog:RefreshTeamState()
  local mainPlayerId = MonopolyWorld.mainPlayer.id
  local mainActorData = MonopolyWorld.MpData:GetActorData(mainPlayerId)
  if mainActorData == nil then
    return
  end
  local buffs = mainActorData.buffs
  setactive(self.ui.mTrans_None, buffs.Count == 0)
  setactive(self.ui.mTrans_List, buffs.Count > 0)
  for i = 0, buffs.Count - 1 do
    local buff = buffs[i]
    local buffDetailItem = self.mBuffPrefabItem[i + 1]
    if buffDetailItem == nil then
      buffDetailItem = ActivityTourBuffDetailItem.New()
      local com = self.ui.mSListChild_Content1.transform:GetComponent(typeof(CS.ScrollListChild))
      buffDetailItem:InitCtrl(com.childItem, self.ui.mSListChild_Content1.transform)
      table.insert(self.mBuffPrefabItem, buffDetailItem)
    end
    buffDetailItem:Refresh(buff, i ~= buffs.Count - 1)
  end
end

function UIActivityTourTeamStateDialog:SetBuffItem(itemLua, buff, showLine)
  if not buff then
    return
  end
  local buffData = TableData.listMonopolyEffectDatas:GetDataById(buff.Id)
  if not buffData then
    return
  end
  itemLua.mIcon.sprite = IconUtils.GetBuffIcon(buffData.icon)
  itemLua.mTxtName.text = buffData.name.str
  local round = buff.RestTurn
  setactive(itemLua.mTrans_Round.gameObject, buffData.turn < 99)
  itemLua.mTxtRound.text = round
  itemLua.mTxtDes.text = buffData.desc.str
  setactive(itemLua.mTrans_Line.gameObject, showLine)
end

function UIActivityTourTeamStateDialog:OnShowFinish()
end

function UIActivityTourTeamStateDialog:OnClose()
  for i, v in pairs(self.mUICharItems) do
    gfdestroy(v:GetRoot())
  end
  self:ReleaseCtrlTable(self.mBuffPrefabItem, true)
end

function UIActivityTourTeamStateDialog:OnRelease()
  self.ui = nil
end

function UIActivityTourTeamStateDialog:AddBtnListener()
  UIUtils.GetButtonListener(self.ui.mBtn_Close1.gameObject).onClick = function()
    UIManager.CloseUI(UIDef.UIActivityTourTeamStateDialog)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Close.gameObject).onClick = function()
    UIManager.CloseUI(UIDef.UIActivityTourTeamStateDialog)
  end
end
