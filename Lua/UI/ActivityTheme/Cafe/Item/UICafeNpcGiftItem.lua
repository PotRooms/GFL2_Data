UICafeNpcGiftItem = class("UICafeNpcGiftItem", UIBaseCtrl)

function UICafeNpcGiftItem:ctor()
end

function UICafeNpcGiftItem:InitCtrl(root, data)
  local instObj = instantiate(UIUtils.GetGizmosPrefab("ActivityCafe/Btn_ActivityCafeGiftIconItem.prefab", self))
  self.ui = {}
  self:LuaUIBindTable(instObj, self.ui)
  UIUtils.AddListItem(instObj.gameObject, root)
  self:SetRoot(instObj.transform)
  self.mUIRoot.localPosition = Vector3(0, 100000, 0)
  setactive(self.mUIRoot, false)
  self.initTimer = TimerSys:DelayCall(1, function()
    setactive(self.mUIRoot, true)
  end)
  self.data = data
  self.camera = data.camera
  self.scene = data.scene
  self.activityEntranceData = data.activityEntranceData
  self.activityModuleData = data.activityModuleData
  self.activityConfigData = data.activityConfigData
  self.uiCamera = UISystem.UICamera
  self.parentRect = self.mUIRoot.parent:GetComponent(typeof(CS.UnityEngine.RectTransform))
  self.mBtn_Self = instObj.transform:GetComponent(typeof(CS.UnityEngine.UI.GFButton))
  self.mAnimator = instObj.transform:GetComponent(typeof(CS.UnityEngine.Animator))
  UIUtils.GetButtonListener(self.mBtn_Self.gameObject).onClick = function()
    local state = NetCmdActivityDarkZone:GetCurrActivityState(self.activityConfigData.Id)
    if state == ActivitySimState.End then
      return
    end
    NetCmdActivitySimData:CSSimCafeClaimNpcGift(self.data.id, function()
      if self.mAnimator ~= nil then
        self.mAnimator:SetTrigger("Get")
      end
      self.timer = TimerSys:DelayCall(0.5, function()
        setactive(self.mUIRoot, false)
      end)
    end)
  end
end

function UICafeNpcGiftItem:UpdateInfo()
end

function UICafeNpcGiftItem:UpdatePos()
  local simHelper = CS.Activities.ActivitySim.ActivitySimHelper.Instance
  if simHelper == nil then
    return
  end
  local model = simHelper.ModelManager:GetActivityModelByConfigId(self.data.id)
  if model == nil then
    return
  end
  if self.camera ~= nil then
    local topPos = self.camera:WorldToScreenPoint(model:GetTopPos())
    self.mUIRoot.localPosition = self.scene:GetModelLocalposition(topPos, self.parentRect, self.uiCamera)
  end
end

function UICafeNpcGiftItem:OnRelease()
  gfdestroy(self.mUIRoot)
  self.ui = nil
  if self.timer ~= nil then
    self.timer:Stop()
    self.timer = nil
  end
  if self.initTimer ~= nil then
    self.initTimer:Stop()
    self.initTimer = nil
  end
end
