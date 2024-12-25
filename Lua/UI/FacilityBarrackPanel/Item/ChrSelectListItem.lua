ChrSelectListItem = class("ChrSelectListItem", UIBaseCtrl)
ChrSelectListItem.__index = ChrSelectListItem

function ChrSelectListItem:ctor()
  self.mGunCmdData = nil
  self.mGunData = nil
end

function ChrSelectListItem:InitCtrl(instObj)
  self.ui = {}
  self:LuaUIBindTable(instObj, self.ui)
  self:SetRoot(instObj.transform)
end

function ChrSelectListItem:SetData(gunCmdData, callback)
  self.mGunCmdData = gunCmdData
  self.mGunData = gunCmdData.gunData
  local gunData = self.mGunData
  IconUtils.GetCharacterHeadSpriteWithClothByGunIdAsync(self.ui.mImg_ChrHead, IconUtils.cCharacterAvatarType_Avatar, gunData.id)
  if not self.mGunCmdData.isLockGun then
    self.ui.mImg_ChrHead.color = ColorUtils.StringToColor("FFFFFF")
  else
    self.ui.mImg_ChrHead.color = CS.UnityEngine.Color(0.403921568627451, 0.44313725490196076, 0.45098039215686275, 0.3764705882352941)
  end
  self.ui.mImg_QualityCor.color = TableData.GetGlobalGun_Quality_Color2(gunData.rank, self.ui.mImg_QualityCor.color.a)
  UIUtils.GetButtonListener(self.ui.mBtn_Overview.gameObject).onClick = function()
    if callback ~= nil then
      callback()
    end
  end
  self:UpdateRedpoint()
end

function ChrSelectListItem:SetSelect(boolean)
  UIUtils.SetInteractive(self.mUIRoot, not boolean)
end

function ChrSelectListItem:UpdateRedpoint()
  TimerSys:DelayFrameCall(1, function()
    local redPoint = self.mGunCmdData:GetGunRedPoint()
    if self.mGunCmdData.isLockGun then
      setactive(self.ui.mObj_RedPoint.gameObject, false)
      setactive(self.ui.mTrans_Load.gameObject, 0 < redPoint)
    else
      setactive(self.ui.mObj_RedPoint.gameObject, 0 < redPoint)
      setactive(self.ui.mTrans_Load.gameObject, false)
    end
  end)
end
