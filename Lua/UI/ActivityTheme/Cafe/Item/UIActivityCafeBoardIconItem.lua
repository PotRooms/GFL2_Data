UIActivityCafeBoardIconItem = class("UIActivityCafeBoardIconItem", UIBaseCtrl)
UIActivityCafeBoardIconItem.offSet = {
  -0.05,
  0.15,
  -0.25,
  0.35,
  -0.45,
  0.05,
  -0.35,
  0.25,
  -0.15,
  0.45
}

function UIActivityCafeBoardIconItem:ctor()
end

function UIActivityCafeBoardIconItem:InitCtrl(instObj, data)
  self.go = instObj.gameObject
  self.isActive = false
  self.mBtn_self = self.go:GetComponent(typeof(CS.UnityEngine.UI.GFButton))
  self.activityConfigData = data.activityConfigData
  self.fallId = data.id
  self.index = data.index
  self.mBtn_self.interactable = true
  UIUtils.GetButtonListener(self.mBtn_self.gameObject).onClick = function()
    local state = NetCmdActivityDarkZone:GetCurrActivityState(self.activityConfigData.Id)
    if state == ActivitySimState.End then
      return
    end
    if NetCmdActivitySimData:IsFullPackage() then
      CS.PopupMessageManager.PopupString(TableData.GetActivityHint(23003006, 2, 2, 3003, 101))
    else
      self.mBtn_self.interactable = false
      NetCmdActivitySimData:CSSimCafeSynthesisCollectOne(self.machineId, self.fallId, function(ret)
        self.mBtn_self.interactable = true
        if ret == ErrorCodeSuc then
          self:RecycleItem()
          MessageSys:SendMessage(CS.GF2.Message.ActivitySimEvent.CafeSynthesisCollectOne, self.fallId)
        end
      end)
    end
  end
  setactive(self.go, false)
end

function UIActivityCafeBoardIconItem:UpdateInfo(data)
  self.data = data
  self.machineId = self.data.machineId
  self.isActive = true
  local simHelper = CS.Activities.ActivitySim.ActivitySimHelper.Instance
  if simHelper == nil then
    return
  end
  local model = simHelper.ModelManager:GetActivityArticleModelByConfigId(self.machineId)
  local posX = model.gameObject.transform.localPosition.x + self.offSet[self.index]
  setactive(self.go, true)
  if data.isNew then
    CS.UITweenManager.PlayLocalPositionTween(self.go.transform, Vector3(model.gameObject.transform.localPosition.x, model.gameObject.transform.localPosition.y + 1, model.gameObject.transform.localPosition.z), Vector3(posX, model.gameObject.transform.localPosition.y, -0.1), 0.3)
  else
    self.go.transform.localPosition = Vector3(posX, model.gameObject.transform.localPosition.y, -0.1)
  end
end

function UIActivityCafeBoardIconItem:RecycleItem()
  self.isActive = false
  setactive(self.go, false)
end

function UIActivityCafeBoardIconItem:OnRelease()
end
