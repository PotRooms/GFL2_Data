UICafeMachineInfoItem = class("UICafeMachineInfoItem", UIBaseCtrl)

function UICafeMachineInfoItem:ctor()
end

function UICafeMachineInfoItem:InitCtrl(root, data)
  local instObj = instantiate(UIUtils.GetGizmosPrefab("ActivityCafe/Btn_ActivityCafeMachineInfoItem.prefab", self))
  self.ui = {}
  self:LuaUIBindTable(instObj, self.ui)
  UIUtils.AddListItem(instObj.gameObject, root)
  self:SetRoot(instObj.transform)
  setactive(self.mUIRoot.gameObject, false)
  self.data = data
  self.activityConfigData = data.activityConfigData
  self.machineData = TableData.listActivitySimArticleDatas:GetDataById(data.id)
  self.camera = data.camera
  self.scene = data.scene
  self.uiCamera = UISystem.UICamera
  self.parentRect = self.mUIRoot.parent:GetComponent(typeof(CS.UnityEngine.RectTransform))
  setactive(self.ui.mTrans_Complete, false)
  self.ui.mText_Complete.text = TableData.GetActivityHint(23003002, 2, 2, 3003, 101)
  setactive(self.ui.mTrans_Warning, false)
  UIUtils.GetButtonListener(self.ui.mBtn_Self.gameObject).onClick = function()
    if NetCmdActivitySimData.SimConfigData and NetCmdActivitySimData:IsIdleStart() then
      UIManager.OpenUIByParam(UIDef.UIActivityCafeDrinkDetailsDialog, {
        id = self.data.id,
        level = self.data.level
      })
    end
  end
  self:UpdateInfo()
end

function UICafeMachineInfoItem:UpdateInfo()
  self.ui.mText_Name.text = self.machineData.article_name_show.str
end

function UICafeMachineInfoItem:UpdatePos(isAddClick)
  local simHelper = self:GetSimHelper()
  if simHelper == nil then
    return
  end
  local model = simHelper.ModelManager:GetActivityArticleModelByConfigId(self.data.id)
  if model ~= nil then
    if isAddClick then
      model:AddClickCallback(function()
        if NetCmdActivitySimData.SimConfigData and NetCmdActivitySimData:IsIdleStart() then
          UIManager.OpenUIByParam(UIDef.UIActivityCafeDrinkDetailsDialog, {
            id = self.data.id,
            level = self.data.level
          })
        end
      end)
    end
    if self.camera ~= nil then
      local topPos = self.camera:WorldToScreenPoint(model:GetTopPos())
      self.mUIRoot.localPosition = self.scene:GetModelLocalposition(topPos, self.parentRect, self.uiCamera)
      if isAddClick then
        setactive(self.mUIRoot.gameObject, true)
      end
    end
  end
end

function UICafeMachineInfoItem:UpdateProduceTime()
  local machineData = NetCmdActivitySimData:GetMachineDataById(self.data.id)
  if machineData.LastProduceTime ~= 0 then
    NetCmdActivitySimData:CSSimCafeDropTimeout(self.data.id)
  else
    self:UpdateState()
  end
end

function UICafeMachineInfoItem:UpdateState()
  local machineData = NetCmdActivitySimData:GetMachineDataById(self.data.id)
  local simHelper = self:GetSimHelper()
  if simHelper == nil then
    return
  end
  local model = simHelper.ModelManager:GetActivityArticleModelByConfigId(self.data.id)
  if NetCmdActivitySimData:IsIdleStart() then
    setactive(self.ui.mTrans_Warning, machineData.LastProduceTime == 0)
    self:UpdateEffectState(model, machineData.LastProduceTime ~= 0)
    local idleData = NetCmdActivitySimData:GetIdleData(self.data.id, self.data.level)
    local leftCount = math.floor(NetCmdItemData:GetItemCountById(idleData.idle_item) / idleData.idle_num)
    local leftTime = leftCount * idleData.outer_cd
    local state = NetCmdActivityDarkZone:GetCurrActivityState(self.activityConfigData.Id)
    if state == ActivitySimState.End then
      model:ChangeWorkState(CS.Activities.ActivitySim.ActivitySimDefine.ArticleWorkState.None)
    elseif machineData.LastProduceTime == 0 then
      model:ChangeWorkState(CS.Activities.ActivitySim.ActivitySimDefine.ArticleWorkState.Rest)
    elseif NetCmdItemData:GetItemCountById(idleData.idle_item) <= idleData.idle_alarm then
      model:ChangeWorkState(CS.Activities.ActivitySim.ActivitySimDefine.ArticleWorkState.Alarm)
    else
      model:ChangeWorkState(CS.Activities.ActivitySim.ActivitySimDefine.ArticleWorkState.Work)
    end
  else
    setactive(self.ui.mTrans_Warning, false)
    self:UpdateEffectState(model, true)
    model:ChangeWorkState(CS.Activities.ActivitySim.ActivitySimDefine.ArticleWorkState.None)
  end
end

function UICafeMachineInfoItem:SetMachineInfoAudio(isEnable)
end

function UICafeMachineInfoItem:UpdateEffectState(go, isActive)
  if go == nil then
    return
  end
  if self.data.id == 997 then
    local transEffect = go.transform:Find("activity_cafe_idle_C/effect")
    if transEffect ~= nil then
      setactive(transEffect, isActive)
    end
  elseif self.data.id == 998 then
    local transLoop = go.transform:Find("activity_cafe_idle_B/sfxLOOP")
    local transStart = go.transform:Find("activity_cafe_idle_B/guodu")
    if transLoop ~= nil then
      if isActive then
        if self.timer ~= nil then
          self.timer:Stop()
          self.timer = nil
        end
        self.timer = TimerSys:DelayCall(0.35, function()
          setactive(transLoop, true)
        end)
      else
        setactive(transLoop, false)
      end
    end
    if transStart ~= nil then
      setactive(transStart, isActive)
    end
  elseif self.data.id == 999 then
    local transLoop = go.transform:Find("activity_cafe_idle_A/sfxLOOP")
    local transStart = go.transform:Find("activity_cafe_idle_A/guodu")
    if transLoop ~= nil then
      if isActive then
        if self.timer ~= nil then
          self.timer:Stop()
          self.timer = nil
        end
        self.timer = TimerSys:DelayCall(0.35, function()
          setactive(transLoop, true)
        end)
      else
        setactive(transLoop, false)
      end
    end
    if transStart ~= nil then
      setactive(transStart, isActive)
    end
  end
end

function UICafeMachineInfoItem:ShowCompleteAnim()
  setactive(self.ui.mTrans_Complete, false)
  setactive(self.ui.mTrans_Complete, true)
end

function UICafeMachineInfoItem:OnRelease()
  if self.timer ~= nil then
    self.timer:Stop()
    self.timer = nil
  end
  setactive(self.ui.mTrans_Complete, false)
  gfdestroy(self.mUIRoot)
  self.ui = nil
end

function UICafeMachineInfoItem:GetSimHelper()
  return CS.Activities.ActivitySim.ActivitySimHelper.Instance
end
