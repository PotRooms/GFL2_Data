require("UI.UIBasePanel")
require("UI.DarkZonePanel.DarkZoneMachineryPanel.item.DarkZoneMachineryLevelInfoItem")
require("UI.Common.UICommonSimpleView")
UIDarkZoneMachineryPanel = class("UIDarkZoneMachineryPanel", UIBasePanel)
UIDarkZoneMachineryPanel.__index = UIDarkZoneMachineryPanel

function UIDarkZoneMachineryPanel:ctor(csPanel)
  self.super.ctor(self, csPanel)
  csPanel.Type = UIBasePanelType.Panel
  csPanel.Is3DPanel = true
end

function UIDarkZoneMachineryPanel:OnInit(root, data)
  self:SetRoot(root)
  self:InitBaseData()
  self.mView:InitCtrl(root, self.ui)
  self:AddBtnListen()
  self.ui.mText_LevelBtn = UIUtils.GetText(self.ui.mBtn_BtnLevelUp.transform, "Root/GrpText/Text_Name")
  self:RefreshLevelInfo(false)
end

function UIDarkZoneMachineryPanel:OnAdditiveSceneLoaded(loadedScene, isOpen)
  self.canChangeCamera = true
  self.carrierScene = SceneSys:GetCarrierScene()
end

function UIDarkZoneMachineryPanel:OnShowStart()
end

function UIDarkZoneMachineryPanel:OnClose()
  self.ui.mBtn_BtnLevelUp.interactable = true
  self.ui = nil
  self.mView = nil
  self.curCarLevel = nil
  self:ReleaseCtrlTable(self.levelInfoItemList, true)
  self.levelInfoItemList = nil
  self.levelFormatStr = nil
  self.costItemFormatStr = nil
  self.redFormatStr = nil
  self.carrierScene = nil
  self.canChangeCamera = nil
  self.super.OnClose(self)
end

function UIDarkZoneMachineryPanel:OnRelease()
  self.super.OnRelease(self)
end

function UIDarkZoneMachineryPanel:InitBaseData()
  self.mView = UICommonSimpleView.New()
  self.ui = {}
  self.maxLevel = 0
  local dataList = TableData.listActivityCarLevelDatas:GetList()
  self.maxLevel = dataList.Count
  self.cofferLevel = NetCmdActivitySimData.CoffeeBarLevel
  local gradeTbData = NetCmdActivitySimData.SimGradeData
  self.limitLevel = 1
  if gradeTbData ~= nil then
    self.limitLevel = gradeTbData.uav_max
  end
  self.curCarLevel = NetCmdActivityDarkZone.mCarLevel
  self.levelInfoItemList = {}
  self.levelFormatStr = TableData.GetHintById(901061)
  self.costItemFormatStr = TableData.GetHintById(112016)
  self.redFormatStr = "<color=#FF5E41>%s</color>"
  
  function self.levelUpFunc1()
    if self.carrierScene and self.isLevelUp then
      self.carrierScene:PlayLevelEffect()
    end
    self:RefreshCostItemInfo()
  end
  
  function self.levelUpFunc2()
    self.ui.mText_Lv.text = string_format(self.levelFormatStr, self.curCarLevel)
  end
  
  function self.levelUpFunc3()
    setactive(self.ui.mScrollListChild_Content, false)
    setactive(self.ui.mScrollListChild_Content, true)
  end
end

function UIDarkZoneMachineryPanel:AddBtnListen()
  UIUtils.GetButtonListener(self.ui.mBtn_Back.gameObject).onClick = function()
    UIManager.CloseUI(UIDef.UIDarkZoneMachineryPanel)
    if NetCmdActivitySimData.IsOpenCafeMain then
    else
    end
    self:CallWithAniDelay(function()
    end)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_BtnLevelUp.gameObject).onClick = function()
    if self.itemEnough == false then
      CS.PopupMessageManager.PopupString(TableData.GetHintById(271033))
    else
      local nextLevel = self.curCarLevel + 1
      self.ui.mBtn_BtnLevelUp.interactable = false
      NetCmdActivityDarkZone:SendDarkZoneCarLevelUp(nextLevel, function()
        self.isLevelUp = true
        self:RefreshLevelInfo(true)
        CS.PopupMessageManager.PopupPositiveString(TableData.GetHintById(271034))
      end)
    end
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Attribute.gameObject).onClick = function()
    UIManager.OpenUI(UIDef.UIDarkZoneMachineryAttributeDialog)
  end
end

function UIDarkZoneMachineryPanel:RefreshLevelInfo(needAnim)
  self.curCarLevel = NetCmdActivityDarkZone.mCarLevel
  self.canLevelUp = self.curCarLevel < self.limitLevel
  self.isNotMaxLevel = self.curCarLevel < self.maxLevel
  self.curLevelData = TableData.listActivityCarLevelDatas:GetDataById(self.curCarLevel)
  local itemListCount = #self.levelInfoItemList
  for i = 1, itemListCount do
    local item = self.levelInfoItemList[i]
    item:SetActive(false)
  end
  if self.isNotMaxLevel == true then
    local nextLevel = self.curCarLevel + 1
    self.nextLevelData = TableData.listActivityCarLevelDatas:GetDataById(nextLevel)
    local skillList = {}
    local info1 = self.nextLevelData.dz_talent
    local count = info1.Count - 1
    for i = 0, count do
      local id = info1[i]
      table.insert(skillList, id)
    end
    info1 = self.nextLevelData.coffee_talent
    count = info1.Count - 1
    for i = 0, count do
      local id = info1[i]
      table.insert(skillList, id)
    end
    local listCount = #skillList
    for i = 1, listCount do
      local id = skillList[i]
      if self.levelInfoItemList[i] == nil then
        self.levelInfoItemList[i] = DarkZoneMachineryLevelInfoItem.New()
        self.levelInfoItemList[i]:InitCtrl(self.ui.mScrollListChild_Content)
      end
      local item = self.levelInfoItemList[i]
      item:SetData(id)
      item:SetActive(true)
    end
  end
  local time1, time2, time3 = 0, 0, 0
  if needAnim == true then
    time1 = 0.4666666666666667
    time2 = 0.8
    time3 = 1.3666666666666667
    local animName = self.isNotMaxLevel == true and "LvUp_Normal" or "LvUp_Full"
    self.ui.mAnimator_Self:SetTrigger(animName)
  end
  if 0 < time1 then
    self:DelayCall(time1, self.levelUpFunc1)
    self:DelayCall(time2, self.levelUpFunc2)
    self:DelayCall(time3, self.levelUpFunc3)
  else
    self.levelUpFunc1()
    self.levelUpFunc2()
    self.levelUpFunc3()
  end
end

function UIDarkZoneMachineryPanel:RefreshCostItemInfo()
  local str = ""
  if self.isNotMaxLevel == false then
    str = TableData.GetHintById(271027)
  elseif self.canLevelUp == false then
    local s = ""
    local configID = NetCmdActivitySimData.offcialConfigId
    local nextLevel = self.cofferLevel + 1
    local d = NetCmdCafeTablet:GetCafeGradeData(nextLevel, configID)
    if d then
      s = d.grade_name.str
    end
    str = string_format(TableData.GetHintById(271035), s)
  else
    str = TableData.GetHintById(271026)
  end
  if self.isLevelUp then
    local showType = self.isNotMaxLevel == true and 0 or 2
    SceneSys:SetCarrierCamera(showType, true)
    self:DelayCall(0.8, function()
      self.ui.mBtn_BtnLevelUp.interactable = self.canLevelUp == true
    end)
  else
    self.ui.mBtn_BtnLevelUp.interactable = self.canLevelUp == true
  end
  self.ui.mText_LevelBtn.text = str
  self.isLevelUp = false
  local nextLevel = self.curCarLevel
  if self.isNotMaxLevel then
    local itemID, itemNum
    for i, v in pairs(self.curLevelData.upgrade_requie) do
      itemID = i
      itemNum = v
    end
    local needItem = itemID ~= 0 and itemNum ~= 0
    if needItem == true then
      local itemCount = NetCmdItemData:GetItemCount(itemID)
      self.ui.mImg_Item.sprite = IconUtils.GetItemIconSprite(itemID)
      self.itemEnough = itemNum <= itemCount
      local itemNumStr = CS.LuaUIUtils.GetMaxNumberText(itemCount)
      if self.itemEnough == false then
        itemNumStr = string.format(self.redFormatStr, itemNumStr)
      end
      itemNum = CS.LuaUIUtils.GetMaxNumberText(itemNum)
      self.ui.mText_Num.text = string_format(self.costItemFormatStr, itemNumStr, itemNum)
      local stcData = TableData.GetItemData(itemID)
      TipsManager.Add(self.ui.mBtn_Consume.gameObject, stcData, nil, true)
    end
    nextLevel = self.curCarLevel + 1
  end
  self.ui.mText_LvNow.text = string_format(self.levelFormatStr, self.curCarLevel)
  self.ui.mText_LvAfter.text = string_format(self.levelFormatStr, nextLevel)
  setactivewithcheck(self.ui.mTrans_MaxLevel, self.isNotMaxLevel == false)
  setactivewithcheck(self.ui.mTrans_Lv, self.isNotMaxLevel == true)
  setactivewithcheck(self.ui.mTrans_Info, self.isNotMaxLevel == true)
  setactivewithcheck(self.ui.mBtn_BtnLevelUp, self.isNotMaxLevel == true)
  setactivewithcheck(self.ui.mBtn_Consume, self.isNotMaxLevel == true)
end

function UIDarkZoneMachineryPanel:OnHideFinish()
end
