require("UI.UIBaseCtrl")
ComChrInfoItemV2 = class("ComChrInfoItemV2", UIBaseCtrl)
ComChrInfoItemV2.__index = ComChrInfoItemV2

function ComChrInfoItemV2:ctor()
end

function ComChrInfoItemV2:InitCtrl(parent)
  local itemPrefab = parent:GetComponent(typeof(CS.ScrollListChild))
  local instObj = instantiate(itemPrefab.childItem)
  self.ui = {}
  self:LuaUIBindTable(instObj, self.ui)
  if parent then
    UIUtils.AddListItem(instObj.gameObject, parent.gameObject)
  end
  self:SetRoot(instObj.transform)
  UIUtils.GetButtonListener(self.ui.mBtn_Self.gameObject).onClick = function()
    self:OnClickSelf()
  end
end

function ComChrInfoItemV2:RefreshData(data)
  self.ui.mText_Level.text = data.Level
  self.ui.mImg_Icon.sprite = IconUtils.GetEnemyCharacterBustSprite(data.RobotTableData.character_pic)
  local color = TableData.GetGlobalGun_Quality_Color2(data.Rank)
  self.ui.mImg_Rank.color = color
end

function ComChrInfoItemV2:RefreshLineUp(data, gunCmdData, isNpc)
  self.isNpc = isNpc
  if data then
    self.ui.mBtn_Self.enabled = true
    local gunId = data.Id
    if isNpc then
      local gunPresetDatas = TableDataBase.listGunPresetDatas:GetDataById(data.Id)
      if gunPresetDatas then
        gunId = gunPresetDatas.SourceId
      end
    end
    if gunCmdData ~= nil then
      self.gunCmdData = gunCmdData
    else
      self.gunCmdData = NetCmdHigherPVPData:GetFullGunData(data)
    end
    self.ui.mText_Level.text = data.Level
    self.ui.mImg_Icon.sprite = IconUtils.GetCharacterTypeSpriteWithClothByGunId(IconUtils.cCharacterAvatarType_Avatar, IconUtils.cCharacterAvatarBust, gunId, data.Costume)
    local gunTabData = TableData.listGunDatas:GetDataById(gunId)
    if gunTabData then
      local dutyData = TableData.listGunDutyDatas:GetDataById(gunTabData.Duty, true)
      local tmpDutyParent = self.ui.mTrans_Duty.transform
      local tmpScrollListChild = tmpDutyParent:GetComponent(typeof(CS.ScrollListChild))
      local tmpDutyObj
      if tmpScrollListChild.transform.childCount > 0 then
        tmpDutyObj = tmpScrollListChild.transform:GetChild(0).gameObject
      else
        tmpDutyObj = instantiate(tmpScrollListChild.childItem.gameObject, tmpDutyParent)
      end
      local tmpDutyImg = tmpDutyObj.transform:Find("Img_DutyIcon").transform:GetComponent(typeof(CS.UnityEngine.UI.Image))
      tmpDutyImg.sprite = IconUtils.GetGunTypeIcon(dutyData.icon)
      self.ui.mImg_Rank.color = TableData.GetGlobalGun_Quality_Color2(gunTabData.rank)
    end
    setactive(self.ui.mTrans_None.gameObject, false)
    setactive(self.ui.mTrans_Content.gameObject, true)
  else
    self.ui.mBtn_Self.enabled = false
    setactive(self.ui.mTrans_None.gameObject, true)
    setactive(self.ui.mTrans_Content.gameObject, false)
  end
end

function ComChrInfoItemV2:OnClickSelf()
  if self.gunCmdData == nil then
    return
  end
  CS.RoleInfoCtrlHelper.Instance:InitSysPlayerAttrData(self.gunCmdData)
end
