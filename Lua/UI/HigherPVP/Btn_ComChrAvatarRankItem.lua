require("UI.UIBaseCtrl")
Btn_ComChrAvatarRankItem = class("Btn_ComChrAvatarRankItem", UIBaseCtrl)
Btn_ComChrAvatarRankItem.__index = Btn_ComChrAvatarRankItem

function Btn_ComChrAvatarRankItem:ctor()
end

function Btn_ComChrAvatarRankItem:InitCtrl(parent)
  local itemPrefab = parent:GetComponent(typeof(CS.ScrollListChild))
  local instObj = instantiate(itemPrefab.childItem)
  self.ui = {}
  self:LuaUIBindTable(instObj, self.ui)
  if parent then
    UIUtils.AddListItem(instObj.gameObject, parent.gameObject)
    CS.LuaUIUtils.SetParent(instObj.gameObject, parent.gameObject, true)
  end
  self:SetRoot(instObj.transform)
  UIUtils.GetButtonListener(self.ui.mBtn_PVPChrAvatarRankItem.gameObject).onClick = function()
    self:OnClickGunAvatar()
  end
end

function Btn_ComChrAvatarRankItem:SetData(data, user)
  self.data = data
  self.user = user
  self.ui.mBtn_PVPChrAvatarRankItem.interactable = data ~= nil
  if data then
    self.ui.mText_Level.text = string_format(TableData.GetHintById(901061), data.Level)
    self.ui.mImg_Avatar.sprite = IconUtils.GetCharacterTypeSpriteWithClothByGunId(IconUtils.cCharacterAvatarType_Avatar, IconUtils.cCharacterAvatarHead, data.Id, data.CostumeId)
    local gunTabData = TableData.listGunDatas:GetDataById(data.Id, true)
    if gunTabData then
      local color = TableData.GetGlobalGun_Quality_Color2(gunTabData.rank)
      self.ui.mImg_Color.color = color
      self.ui.mImg_Duty.sprite = IconUtils.GetGunTypeIconByDuty(gunTabData.duty)
    end
    setactive(self.ui.mTrans_GrpIconRoot.gameObject, true)
    setactive(self.ui.mTrans_QualityRoot.gameObject, true)
    setactive(self.ui.mTrans_LevelRoot.gameObject, true)
    setactive(self.ui.mTrans_PlayerInfo.gameObject, true)
    setactive(self.ui.mTrans_Empty.gameObject, false)
  else
    setactive(self.ui.mTrans_GrpIconRoot.gameObject, false)
    setactive(self.ui.mTrans_QualityRoot.gameObject, false)
    setactive(self.ui.mTrans_LevelRoot.gameObject, false)
    setactive(self.ui.mTrans_PlayerInfo.gameObject, false)
    setactive(self.ui.mTrans_Empty.gameObject, true)
  end
end

function Btn_ComChrAvatarRankItem:OnClickGunAvatar()
  if self.data == nil or self.user == nil then
    return
  end
  NetCmdHigherPVPData:MsgCsHighPvpRankGunDetail(self.user.Uid, self.data.Id, function(ret)
    if ret == ErrorCodeSuc and NetCmdHigherPVPData.isFound then
      CS.RoleInfoCtrlHelper.Instance:InitSysPlayerAttrData(NetCmdHigherPVPData.selectGunData)
    end
  end)
end
