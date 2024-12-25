require("UI.UIBasePanel")
require("UI.MonopolyActivity.ActivityTourGlobal")
require("UI.MonopolyActivity.Heal.Item.Btn_ActivityTourTreatmentChrItem")
ActivityTourTreatmentSelectDialog = class("ActivityTourTreatmentSelectDialog", UIBasePanel)
ActivityTourTreatmentSelectDialog.__index = ActivityTourTreatmentSelectDialog

function ActivityTourTreatmentSelectDialog:ctor(csPanel)
  self.super.ctor(self, csPanel)
  csPanel.Type = UIBasePanelType.Dialog
end

function ActivityTourTreatmentSelectDialog:OnAwake(root, data)
  self:SetRoot(root)
  self.ui = {}
  self.listItem = {}
  self:LuaUIBindTable(root, self.ui)
  self:AddBtnListener()
  MonopolyUtil:SetMonopolyActivityUIHint(root)
end

function ActivityTourTreatmentSelectDialog:OnInit(root, data)
  self.taskType = data.taskType
  self.uiType = data.uiType
  self.callBack = data.callBack
  self.limit = data.limit
  self.healNum = data.healNum
  self.selectTip = data.selectTip
  self.listSelId = {}
  self.teamInfo = {}
  local isRestart = self.taskType == CS.GF2.Monopoly.TaskType.Restart
  local teamInfo = MonopolyWorld.MpData.teamInfo
  for i = 0, teamInfo.Count - 1 do
    if self.uiType == ActivityTourGlobal.TreatmentSelectDialog_UIType.Heal then
      if isRestart then
        if 0 >= teamInfo[i].HpPercent then
          table.insert(self.teamInfo, teamInfo[i])
        end
      elseif 0 < teamInfo[i].HpPercent and teamInfo[i].HpPercent < ActivityTourGlobal.MaxHp then
        table.insert(self.teamInfo, teamInfo[i])
      end
    elseif 0 < teamInfo[i].HpPercent and teamInfo[i].Ip.WillValue < ActivityTourGlobal.GetMaxWillValue(teamInfo[i].Id) then
      table.insert(self.teamInfo, teamInfo[i])
    end
  end
  self.maxNum = math.min(self.limit, #self.teamInfo)
  self:Refresh()
end

function ActivityTourTreatmentSelectDialog:OnShowStart()
end

function ActivityTourTreatmentSelectDialog:OnClose()
end

function ActivityTourTreatmentSelectDialog:OnRelease()
  self.ui = nil
  self:ReleaseCtrlTable(self.listItem, true)
end

function ActivityTourTreatmentSelectDialog:AddBtnListener()
  UIUtils.GetButtonListener(self.ui.mBtn_Cancel.gameObject).onClick = function()
    self:OnBtnCancel()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Confirm.gameObject).onClick = function()
    self:OnBtnConfirm()
  end
end

function ActivityTourTreatmentSelectDialog:OnBtnCancel()
  local tip = ""
  if self.taskType == CS.GF2.Monopoly.TaskType.Func then
    if self.uiType == ActivityTourGlobal.TreatmentSelectDialog_UIType.Heal then
      tip = MonopolyUtil:GetMonopolyActivityHint(270231)
    else
      tip = MonopolyUtil:GetMonopolyActivityHint(270232)
    end
  elseif self.taskType == CS.GF2.Monopoly.TaskType.Restart then
    tip = MonopolyUtil:GetMonopolyActivityHint(270407)
  elseif self.uiType == ActivityTourGlobal.TreatmentSelectDialog_UIType.Heal then
    tip = MonopolyUtil:GetMonopolyActivityHint(270289)
  else
    tip = MonopolyUtil:GetMonopolyActivityHint(270290)
  end
  MessageBoxPanel.ShowDoubleType(tip, function()
    self:SendHeal(true)
  end)
end

function ActivityTourTreatmentSelectDialog:OnBtnConfirm()
  if #self.listSelId <= 0 then
    CS.PopupMessageManager.PopupString(MonopolyUtil:GetMonopolyActivityHint(270267))
    return
  end
  if #self.listSelId < self.maxNum then
    local tip = ""
    if self.uiType == ActivityTourGlobal.TreatmentSelectDialog_UIType.Heal then
      if self.taskType == CS.GF2.Monopoly.TaskType.Restart then
        tip = MonopolyUtil:GetMonopolyActivityHint(270408)
      else
        tip = MonopolyUtil:GetMonopolyActivityHint(270233)
      end
    else
      tip = MonopolyUtil:GetMonopolyActivityHint(270234)
    end
    MessageBoxPanel.ShowDoubleType(tip, function()
      self:SendHeal()
    end)
    return
  end
  self:SendHeal()
end

function ActivityTourTreatmentSelectDialog:SendHeal(isCancel)
  local tmpList = new_list(typeof(CS.System.UInt32))
  if not isCancel then
    local teamInfo = MonopolyWorld.MpData.teamInfo
    for i = 1, #self.listSelId do
      local gunId = self.listSelId[i]
      for j = 0, teamInfo.Count - 1 do
        if gunId == teamInfo[j].Id then
          tmpList:Add(gunId)
          break
        end
      end
    end
  end
  if self.callBack ~= nil then
    if isCancel then
      self.callBack(-1, tmpList)
    else
      self.callBack(0, tmpList)
    end
  end
  self.callBack = nil
  UIManager.CloseUI(UIDef.ActivityTourTreatmentSelectDialog)
end

function ActivityTourTreatmentSelectDialog:Refresh()
  self:RefreshPlayer()
  self:RefreshHeal()
  self:RefreshSteadyContent()
end

function ActivityTourTreatmentSelectDialog:RefreshHeal()
  if self.uiType ~= ActivityTourGlobal.TreatmentSelectDialog_UIType.Heal then
    return
  end
  if self.taskType == CS.GF2.Monopoly.TaskType.Func then
    self.ui.mText_Title.text = MonopolyUtil:GetMonopolyActivityHint(270235)
  elseif self.taskType == CS.GF2.Monopoly.TaskType.Restart then
    self.ui.mText_Title.text = MonopolyUtil:GetMonopolyActivityHint(270404)
  else
    self.ui.mText_Title.text = MonopolyUtil:GetMonopolyActivityHint(270287)
  end
  self:RefreshSelectInfo()
end

function ActivityTourTreatmentSelectDialog:RefreshSteadyContent()
  if self.uiType ~= ActivityTourGlobal.TreatmentSelectDialog_UIType.Steady then
    return
  end
  if self.taskType == CS.GF2.Monopoly.TaskType.Func then
    self.ui.mText_Title.text = MonopolyUtil:GetMonopolyActivityHint(270237)
  else
    self.ui.mText_Title.text = MonopolyUtil:GetMonopolyActivityHint(270288)
  end
  self:RefreshSelectInfo()
end

function ActivityTourTreatmentSelectDialog:RefreshSelectInfo()
  self.ui.mText_Tips.text = string_format(self.selectTip, #self.listSelId, self.maxNum)
end

function ActivityTourTreatmentSelectDialog:RefreshPlayer()
  local teamNum = #self.teamInfo
  for i = 1, teamNum do
    local item = self.listItem[i]
    if not item then
      item = Btn_ActivityTourTreatmentChrItem.New()
      item:InitCtrl(self.ui.mScrollList_Content.transform)
      self.listItem[i] = item
    end
    local isGray = self.taskType == CS.GF2.Monopoly.TaskType.Restart
    item:SetData(i, self.uiType, self.SelectItem, self.teamInfo[i], self.healNum, isGray)
  end
end

function ActivityTourTreatmentSelectDialog.SelectItem(gunId)
  self = ActivityTourTreatmentSelectDialog
  local findIndex = 0
  for i = 1, #self.listSelId do
    if self.listSelId[i] == gunId then
      findIndex = i
      break
    end
  end
  if 0 < findIndex then
    table.remove(self.listSelId, findIndex)
  else
    if #self.listSelId >= self.maxNum then
      CS.PopupMessageManager.PopupString(MonopolyUtil:GetMonopolyActivityHint(270312))
      return
    end
    self.listSelId[#self.listSelId + 1] = gunId
  end
  for i = 1, #self.teamInfo do
    local item = self.listItem[i]
    if item then
      item:SetSelect(gunId)
    end
  end
  self:RefreshSelectInfo()
end
