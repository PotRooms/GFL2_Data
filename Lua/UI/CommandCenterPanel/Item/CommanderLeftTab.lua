require("UI.UIBaseCtrl")
CommanderLeftTab = class("CommanderLeftTab", UIBaseCtrl)
CommanderLeftTab.__index = CommanderLeftTab

function CommanderLeftTab:ctor()
  self.systemId = 0
end

function CommanderLeftTab:__InitCtrl()
end

function CommanderLeftTab:InitCtrl(parent)
  local obj
  obj = instantiate(UIUtils.GetGizmosPrefab("CommandCenter/Btn_CommandCenterLeftTabItem.prefab", self))
  self:SetRoot(obj.transform)
  self.ui = {}
  self:LuaUIBindTable(self.mUIRoot, self.ui)
  self:__InitCtrl()
  self.btn = self.ui.mBtn_Self
  self.animator = self.ui.mAni_Root
  self.animator.keepAnimatorControllerStateOnDisable = true
  self.transRedPoint = self.ui.mTrans_RedPoint
  self.transRedPointNode = self.ui.mTrans_RedPointNode
  self.transActivitiesOpen = self.ui.mTrans_ActivitieOpen
  if parent then
    CS.LuaUIUtils.SetParent(obj.gameObject, parent.gameObject, false)
  end
end

function CommanderLeftTab:OnRelease()
  self:DestroySelf()
end

function CommanderLeftTab:SetData(data, systemId)
  self.systemId = systemId or 0
  self.ui.mText_Title.text = data.name.str
  local layoutElement = self.ui.mText_Title.transform:GetComponent(typeof(CS.UnityEngine.UI.LayoutElement))
  TimerSys:DelayFrameCall(1, function()
    if layoutElement ~= nil then
      local contentSize = LuaUtils.GetRectTransformSize(self.ui.mText_Title.transform.gameObject)
      layoutElement.minWidth = math.ceil(contentSize.x) + 4
    end
  end)
  local num1 = math.random(10, 99)
  local num2 = math.random(1000, 9999)
  local num3 = math.random(10, 99)
  self.ui.mText_Random.text = "//." .. num1 .. "." .. num2 .. "." .. num3
  self:UpdateData()
end

function CommanderLeftTab:UpdateUpTips()
  if self.systemId == 13000 and not self.isLock then
    setactive(self.ui.mTrans_Up, GashaponNetCmdHandler:HasUpPool())
  end
end

function CommanderLeftTab:UpdateData()
  self.isLock = not AccountNetCmdHandler:CheckSystemIsUnLock(self.systemId)
  setactive(self.ui.mTrans_Locked, self.isLock)
  setactive(self.ui.mTrans_Unlock, not self.isLock)
  if self.animator then
    self.animator:SetBool("Unlock", not self.isLock)
  end
end
