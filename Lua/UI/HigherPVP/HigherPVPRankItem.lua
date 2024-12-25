require("UI.UIBaseCtrl")
require("UI.Common.UICommonPlayerAvatarItem")
HigherPVPRankItem = class("HigherPVPRankItem", UIBaseCtrl)
HigherPVPRankItem.__index = HigherPVPRankItem

function HigherPVPRankItem:ctor()
end

function HigherPVPRankItem:InitCtrl(parent)
  local itemPrefab = parent:GetComponent(typeof(CS.ScrollListChild))
  local instObj = instantiate(itemPrefab.childItem)
  self.ui = {}
  self:LuaUIBindTable(instObj, self.ui)
  if parent then
    UIUtils.AddListItem(instObj.gameObject, parent.gameObject)
    CS.LuaUIUtils.SetParent(instObj.gameObject, parent.gameObject, true)
  end
  self:SetRoot(instObj.transform)
end

function HigherPVPRankItem:InitCtrlWithoutInstantiate(obj)
  self:SetRoot(obj.transform)
  self.ui = {}
  self:LuaUIBindTable(obj, self.ui)
  self.selfAvatarList = {}
  for i = 1, 4 do
    local cell = Btn_ComChrAvatarRankItem.New()
    cell:InitCtrl(self.ui.mTrans_ChrList)
    table.insert(self.selfAvatarList, cell)
  end
end

function HigherPVPRankItem:SetData(data)
  if data.user == nil then
    self.ui.mText_PlayerName.text = TableData.GetHintById(100)
    self.ui.mText_Level.text = TableData.GetHintById(82001) .. 1
    if data.rankInfo then
      self.ui.mText_Num.text = data.rankInfo.Rank
      self.ui.mText_Num1.text = data.rankInfo.Point
    end
    for i = 1, #self.selfAvatarList do
      local cell = self.selfAvatarList[i]
      cell:SetData(nil, nil)
    end
    if self.playerAvatar == nil then
      self.playerAvatar = UICommonPlayerAvatarItem.New()
      self.playerAvatar:InitCtrl(self.ui.mTrans_PlayerAvatar)
    end
    self.playerAvatar:SetData(TableData.GetPlayerAvatarIconById(21999, 0))
    return
  end
  self.ui.mText_PlayerName.text = data.user.Name
  self.ui.mText_Level.text = TableData.GetHintById(82001) .. data.user.Level
  if data.rankInfo then
    self.ui.mText_Num.text = data.rankInfo.Rank
    self.ui.mText_Num1.text = data.rankInfo.Point
    for i = 1, #self.selfAvatarList do
      local cell = self.selfAvatarList[i]
      if i <= data.rankInfo.Avatars.Count then
        cell:SetData(data.rankInfo.Avatars[i - 1], data.user)
      else
        cell:SetData(nil, data.user)
      end
    end
  end
  if self.playerAvatar == nil then
    self.playerAvatar = UICommonPlayerAvatarItem.New()
    self.playerAvatar:InitCtrl(self.ui.mTrans_PlayerAvatar)
  end
  self.playerAvatar:SetData(TableData.GetPlayerAvatarIconById(data.user.Portrait, LuaUtils.EnumToInt(data.user.Sex)))
  if data.user.PortraitFrame and 0 < data.user.PortraitFrame then
    local frameData = TableData.listHeadFrameDatas:GetDataById(data.user.PortraitFrame, true)
    if frameData then
      self.playerAvatar:SetFrameDataOut(frameData.icon)
    end
  end
  self.playerAvatar:AddBtnListener(function()
    local mRolePublicCmdData = CS.RolePublicCmdData(data.user)
    if mRolePublicCmdData.UID == AccountNetCmdHandler:GetUID() then
      return
    end
    LuaUtils.OpenUIPlayerInfoDialog(mRolePublicCmdData)
  end)
end

function HigherPVPRankItem:OnRelease()
  if self.playerAvatar then
    self.playerAvatar:OnRelease()
  end
  self.playerAvatar = nil
end
