require("UI.UIBasePanel")
require("UI.Common.UIComTabBtn1ItemV2")
require("UI.DarkZonePanel.DarkZoneMachineryPanel.item.DarkZoneMachineryAttributeItem")
require("UI.Common.UICommonSimpleView")
UIDarkZoneMachineryAttributeDialog = class("UIDarkZoneMachineryAttributeDialog", UIBasePanel)
UIDarkZoneMachineryAttributeDialog.__index = UIDarkZoneMachineryAttributeDialog

function UIDarkZoneMachineryAttributeDialog:ctor(csPanel)
  self.super.ctor(self, csPanel)
  csPanel.Type = UIBasePanelType.Dialog
end

function UIDarkZoneMachineryAttributeDialog:OnInit(root, data)
  self.grayMaterial = ResSys:GetEffectMaterial("CombatChrList2ItemV2_ImgAvatar_Desaturation")
  self._DesaturationID = CS.UnityEngine.Shader.PropertyToID("_Desaturation")
  self.grayMaterial:SetFloat(self._DesaturationID, 1)
  self:SetRoot(root)
  self:InitBaseData()
  self.mView:InitCtrl(root, self.ui)
  self:AddBtnListen()
  self:RefreshTabItem()
  
  function self.ui.mGridScroller_BuffList.itemCreated(renderData)
    self:ItemProvider(renderData)
  end
  
  function self.ui.mGridScroller_BuffList.itemRenderer(index, rendererData)
    self:ItemRenderer(index, rendererData)
  end
end

function UIDarkZoneMachineryAttributeDialog:OnShowStart()
  self:ClickTabItem(self.tabItemList[1])
end

function UIDarkZoneMachineryAttributeDialog:OnClose()
  ResourceManager:UnloadAsset(self.grayMaterial)
  self.grayMaterial = nil
  self.ui = nil
  self.mView = nil
  self.curActivity = nil
  self.curCarLevel = nil
  self.curLevelInfoItem = nil
  self:ReleaseCtrlTable(self.levelInfoItemList, true)
  self.levelInfoItemList = nil
  self:ReleaseCtrlTable(self.tabItemList, true)
  self.tabItemList = nil
  self.curTabItem = nil
  self.super.OnClose(self)
end

function UIDarkZoneMachineryAttributeDialog:OnRelease()
  self.super.OnRelease(self)
end

function UIDarkZoneMachineryAttributeDialog:InitBaseData()
  self.mView = UICommonSimpleView.New()
  self.ui = {}
  local dataList = TableData.listActivityCarLevelDatas:GetList()
  self.maxLevel = dataList.Count
  self.curCarLevel = NetCmdActivityDarkZone.mCarLevel
  self.curActivity = NetCmdActivityDarkZone.mActivityID
  self.levelInfoItemList = {}
  self.tabItemList = {}
  self.coffeeEffectIDList = {}
  self.dzEffectIDList = {}
  for i = 0, self.maxLevel - 1 do
    local levelNum = i + 1
    local tbData = TableData.listActivityCarLevelDatas:GetDataById(levelNum)
    local info1 = tbData.dz_talent
    local count = info1.Count - 1
    for j = 0, count do
      local t = {}
      t.id = info1[j]
      t.level = levelNum
      t.tbData = TableData.listActivityCarTalentDatas:GetDataById(t.id)
      table.insert(self.dzEffectIDList, t)
    end
    info1 = tbData.coffee_talent
    count = info1.Count - 1
    for j = 0, count do
      local t = {}
      t.id = info1[j]
      t.level = levelNum
      t.tbData = TableData.listActivityCarTalentDatas:GetDataById(t.id)
      table.insert(self.coffeeEffectIDList, t)
    end
  end
  self.levelFormatStr = TableData.GetHintById(901061)
  self.infoUnlockStr = TableData.GetHintById(102244)
end

function UIDarkZoneMachineryAttributeDialog:AddBtnListen()
  local f = function()
    UIManager.CloseUI(UIDef.UIDarkZoneMachineryAttributeDialog)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Close.gameObject).onClick = f
  UIUtils.GetButtonListener(self.ui.mBtn_BGClose.gameObject).onClick = f
end

function UIDarkZoneMachineryAttributeDialog:ItemProvider(renderData)
  local itemView = DarkZoneMachineryAttributeItem.New()
  itemView:InitCtrlWithNoInstantiate(renderData.gameObject, false)
  itemView:SetMaterial(self.grayMaterial)
  itemView:AddClickListener(function()
    self:ClickAttributeItem(itemView)
  end)
  renderData.data = itemView
end

function UIDarkZoneMachineryAttributeDialog:ItemRenderer(index, renderData)
  local t = self.showSkillList[index + 1]
  local item = renderData.data
  local isUnlock = t.level <= self.curCarLevel
  item:SetData(t.tbData, isUnlock, t.level, index)
  item:SetBtnInteractable(self.curSelectInfoItem == t.id)
end

function UIDarkZoneMachineryAttributeDialog:RefreshLevelInfo(type)
  local skillList = type == 2 and self.coffeeEffectIDList or self.dzEffectIDList
  self.showSkillList = skillList
  local count = #self.showSkillList
  if 0 < count then
    local d = self.showSkillList[1]
    local isUnlock = d.level <= self.curCarLevel
    self:RefreshAttributeInfo(d.tbData, isUnlock, d.level, 0)
  end
  self.ui.mGridScroller_BuffList.numItems = #self.showSkillList
  self.ui.mGridScroller_BuffList:Refresh()
end

function UIDarkZoneMachineryAttributeDialog:RefreshTabItem()
  local hintIdList = {271097, 271098}
  for i = 1, 2 do
    if self.tabItemList[i] == nil then
      self.tabItemList[i] = UIComTabBtn1ItemV2.New()
      local data = {
        index = i,
        name = TableData.GetHintById(hintIdList[i])
      }
      self.tabItemList[i]:InitCtrl(self.ui.mTrans_TabBtn, data)
    end
    local item = self.tabItemList[i]
    item:AddClickListener(function()
      self:ClickTabItem(item)
    end)
  end
end

function UIDarkZoneMachineryAttributeDialog:ClickTabItem(item)
  if item == self.curTabItem then
    return
  end
  if self.curTabItem ~= nil then
    self.curTabItem:SetBtnInteractable(true)
  end
  self.curTabItem = item
  self.curTabItem:SetBtnInteractable(false)
  self:RefreshLevelInfo(item.index)
end

function UIDarkZoneMachineryAttributeDialog:ClickAttributeItem(item)
  local lastIndex = self.curSelectInfoItemIndex
  self:RefreshAttributeInfo(item.tableData, item.isUnlock, item.unlockLevel, item.itemIndex)
  if self.curSelectInfoItemIndex then
    self.ui.mGridScroller_BuffList:RefreshItemByIndex(self.curSelectInfoItemIndex)
  end
  if lastIndex then
    self.ui.mGridScroller_BuffList:RefreshItemByIndex(lastIndex)
  end
end

function UIDarkZoneMachineryAttributeDialog:RefreshAttributeInfo(data, isUnlock, unlockLevel, index)
  self.ui.mText_Name.text = data.talent_name.str
  self.ui.mText_Detail.text = data.talent_des.str
  setactivewithcheck(self.ui.mTrans_Lock, isUnlock == false)
  if isUnlock == false then
    self.ui.mText_Lock.text = string_format(self.infoUnlockStr, unlockLevel)
  end
  self.curSelectInfoItem = data.id
  self.curSelectInfoItemIndex = index
end
