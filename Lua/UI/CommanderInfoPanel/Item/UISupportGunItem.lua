require("UI.UIBaseCtrl")
UISupportGunItem = class("UISupportGunItem", UIBaseCtrl)
UISupportGunItem.__index = UISupportGunItem

function UISupportGunItem:ctor(parentPanel)
  self.parentObj = nil
  self.equipGun = nil
  self.equipGunId = 0
  self.gunList = {}
  self.gunDataList = {}
  self.gunItemList = {}
  self.dutyList = {}
  self.curDuty = nil
  self.sortContent = nil
  self.sortList = {}
  self.curSort = nil
  self.curGun = nil
  self.curGunId = 0
  self.itemList = {}
  self.callback = nil
  self.parentPanel = parentPanel
end

function UISupportGunItem:__InitCtrl()
  self.mBtn_Replace = UIUtils.GetTempBtn(self:GetRectTransform("Root/GrpLeft/Content/GrpAction/BtnConfirm"))
  self.mBtn_Close = self:GetButton("Root/Btn_Close")
  self.mBtn_Duty = self:GetButton("Root/GrpLeft/Content/GrpElementScreen/BtnScreen/Btn_Screen")
  self.mTrans_DutyContent = self:GetRectTransform("Root/GrpLeft/Content/GrpElementScreen/Trans_GrpScreenList")
  self.mTrans_SortContent = self:GetRectTransform("Root/GrpLeft/Content/GrpScreen/BtnScreen")
  self.mTrans_SortList = self:GetRectTransform("Root/GrpLeft/Content/GrpScreen/Trans_GrpScreenList")
  self.mTrans_GunList = self:GetRectTransform("Root/GrpLeft/Content/GrpSupChrList/Viewport/Content")
  self.mTrans_Confirm = self:GetRectTransform("Root/GrpLeft/Content/GrpAction/BtnConfirm")
  self.mTrans_Used = self:GetRectTransform("Root/GrpLeft/Content/GrpAction/Trans_Used")
  self.mImage_DutyIcon = self:GetImage("Root/GrpLeft/Content/GrpElementScreen/BtnScreen/Btn_Screen/Img_Icon")
  self.mAniTime = UIUtils.GetRectTransform(self.mUIRoot, "Root"):GetComponent("AniTime")
  self.mAnimator = UIUtils.GetRectTransform(self.mUIRoot, "Root"):GetComponent("Animator")
  self.virtualList = self:GetVirtualListEx("Root/GrpLeft/Content/GrpSupChrList")
  
  function self.virtualList.itemProvider()
    local item = self:ItemProvider()
    return item
  end
  
  function self.virtualList.itemRenderer(index, renderData)
    self:ItemRenderer(index, renderData)
  end
  
  self.virtualList.numItems = #self.itemList
  self.virtualList:Refresh()
  UIUtils.GetButtonListener(self.mBtn_Close.gameObject).onClick = function()
    self:CloseSupportGunList()
  end
  UIUtils.GetButtonListener(self.mBtn_Duty.gameObject).onClick = function()
    self:OnClickElementList()
  end
  UIUtils.GetButtonListener(self.mBtn_Replace.gameObject).onClick = function()
    self:OnClickReplaceGun()
  end
end

function UISupportGunItem:InitCtrl(parent, callback)
  local obj = instantiate(UIUtils.GetGizmosPrefab("CommanderInfo/CommanderSupChrReplaceItemV2.prefab", self))
  if parent then
    obj.transform:SetParent(parent.transform, false)
    obj.transform.localPosition = vectorzero
    obj.transform.anchoredPosition = vector2zero
  end
  self.parentObj = parent
  self.callback = callback
  self:SetRoot(obj.transform)
  self:__InitCtrl()
  self:InitGunList()
  self:InitSortContent()
  self:InitElementList()
end

function UISupportGunItem:SetData(gunId)
  self.equipGunId = gunId
  self.curGunId = gunId
  self:OnClickElement(self.curDuty)
  setactive(self.mTrans_Used, true)
  setactive(self.mTrans_Confirm, false)
end

function UISupportGunItem:ItemProvider()
  local itemView = UIBarrackChrCardItem.New()
  itemView:InitCtrl(self.mTrans_GunList.transform)
  local renderDataItem = CS.RenderDataItem()
  renderDataItem.renderItem = itemView:GetRoot().gameObject
  renderDataItem.data = itemView
  table.insert(self.gunItemList, itemView)
  return renderDataItem
end

function UISupportGunItem:ItemRenderer(index, renderData)
  local data = self.itemList[index + 1]
  local item = renderData.data
  item:SetData(data.id, false)
  item.index = index + 1
  item:SetSelectBlack(data.id == self.equipGunId)
  if data.id == self.equipGunId then
    self.equipGun = item
  end
  item:SetSelect(data.id == self.curGunId)
  if data.id == self.curGunId then
    self.curGun = item
  end
  UIUtils.GetButtonListener(item.mBtn_Gun.gameObject).onClick = function()
    self:OnGunClick(item)
  end
end

function UISupportGunItem:OnGunClick(gun)
  if gun then
    if self.curGun then
      if self.curGun.tableData.id == gun.tableData.id then
        return
      end
      self.curGun:SetSelect(false)
    end
    gun:SetSelect(true)
    self.curGun = gun
    self.curGunId = gun.tableData.id
    setactive(self.mTrans_Used, gun.tableData.id == self.equipGunId)
    setactive(self.mTrans_Confirm, gun.tableData.id ~= self.equipGunId)
  end
end

function UISupportGunItem:UpdateGunList()
  self.gunList = self:GetGunListByDuty(self.curDuty.type)
  self.curGun = nil
  self.equipGun = nil
  local sortFunc = FacilityBarrackGlobal:GetSortFunc(1, self.curSort.sortCfg, self.curSort.isAscend)
  table.sort(self.gunList, sortFunc)
  for _, gun in ipairs(self.gunItemList) do
    gun:SetData(nil)
    gun:SetSelect(false)
  end
  self.itemList = {}
  if self.gunList then
    for i = 1, #self.gunList do
      local item
      local data = self.gunList[i]
      table.insert(self.itemList, data)
    end
  end
  self.virtualList.numItems = #self.itemList
  self.virtualList:Refresh()
end

function UISupportGunItem:GetGunListByDuty(duty)
  if duty then
    local tempGunList = {}
    if duty == 0 then
      for _, gunList in pairs(self.gunDataList) do
        if gunList then
          for _, gunId in ipairs(gunList) do
            local data = NetCmdTeamData:GetGunByID(gunId)
            if data ~= nil then
              table.insert(tempGunList, data)
            end
          end
        end
      end
    else
      local gunIdList = self.gunDataList[duty]
      if gunIdList then
        for _, gunId in ipairs(gunIdList) do
          local data = NetCmdTeamData:GetGunByID(gunId)
          if data ~= nil then
            table.insert(tempGunList, data)
          end
        end
      end
    end
    return tempGunList
  end
  return nil
end

function UISupportGunItem:OnClickElement(item)
  if item then
    if self.curDuty and self.curDuty.type ~= item.type then
      self.curDuty.txtName.color = self.textcolor.BeforeSelected
      self.curDuty.imgIcon.color = self.textcolor.ImgBeforeSelected
      setactive(self.curDuty.grpset, false)
    end
    self.curDuty = item
    self.curDuty.txtName.color = self.textcolor.AfterSelected
    self.curDuty.imgIcon.color = self.textcolor.ImgAfterSelected
    setactive(self.curDuty.grpset, true)
    self:OnClickSort(self.curSort.sortType)
    self:CloseElement()
    self.mImage_DutyIcon.sprite = IconUtils.GetGunTypeIcon(self.curDuty.data.icon .. "_W")
  end
end

function UISupportGunItem:OnClickSortList()
  setactive(self.mTrans_SortList, true)
end

function UISupportGunItem:CloseItemSort()
  setactive(self.mTrans_SortList, false)
end

function UISupportGunItem:OnClickElementList()
  setactive(self.mTrans_DutyContent, true)
end

function UISupportGunItem:CloseElement()
  setactive(self.mTrans_DutyContent, false)
end

function UISupportGunItem:CloseSupportGunList()
  if self.mAniTime and self.mAnimator then
    self.mAnimator:SetTrigger("FadeOut")
    TimerSys:DelayCall(self.mAniTime.m_FadeOutTime, function()
      setactive(self.parentObj, false)
    end)
  else
    setactive(self.parentObj, false)
  end
end

function UISupportGunItem:OnClickSort(type)
  if type then
    if self.curSort and self.curSort.sortType ~= type then
      self.curSort.txtName.color = self.textcolor.BeforeSelected
      setactive(self.curSort.grpset, false)
    end
    self.curSort = self.sortList[type]
    self.curSort.txtName.color = self.textcolor.BeforeSelected
    setactive(self.curSort.grpset, false)
    self.sortContent:SetData(self.curSort)
    for i = 1, #self.sortList do
      if self.sortList[i].sortType ~= self.curSort.sortType then
        self.sortList[i].txtName.color = self.textcolor.BeforeSelected
        setactive(self.sortList[i].grpset, false)
      else
        self.sortList[i].txtName.color = self.textcolor.AfterSelected
        setactive(self.sortList[i].grpset, true)
      end
    end
    self:UpdateGunList()
    self:CloseItemSort()
  end
end

function UISupportGunItem:OnClickAscend()
  if self.curSort then
    self.curSort.isAscend = not self.curSort.isAscend
    self:UpdateGunList()
  end
end

function UISupportGunItem:OnClickReplaceGun()
  if self.curGunId == self.equipGunId then
    return
  end
  if self.callback then
    self.callback(self.curGunId)
    self:CloseSupportGunList()
  end
end

function UISupportGunItem:InitGunList(curId)
  self.gunDataList = {}
  for i = 0, NetCmdTeamData.GunList.Count - 1 do
    local gunData = NetCmdTeamData.GunList[i]
    if self.gunDataList[gunData.TabGunData.duty] == nil then
      self.gunDataList[gunData.TabGunData.duty] = {}
    end
    table.insert(self.gunDataList[gunData.TabGunData.duty], gunData.id)
  end
end

function UISupportGunItem:InitElementList()
  self.dutyList = {}
  local dutyDataList = {}
  local data = {}
  data.id = 0
  data.icon = "Icon_Professional_ALL"
  table.insert(dutyDataList, data)
  local list = TableData.listGunDutyDatas:GetList()
  for i = 0, list.Count - 1 do
    local data = list[i]
    table.insert(dutyDataList, data)
  end
  local sortList = self:InstanceUIPrefab("UICommonFramework/ComScreenDropdownListItemV2.prefab", self.mTrans_DutyContent)
  local parent = UIUtils.GetRectTransform(sortList, "Content")
  for i = 1, #dutyDataList do
    local data = dutyDataList[i]
    local obj = self:InstanceUIPrefab("Character/ChrEquipSuitDropdownItemV2.prefab", parent)
    if obj then
      local duty = {}
      duty.obj = obj
      duty.data = data
      duty.btnSort = UIUtils.GetButton(obj)
      duty.txtName = UIUtils.GetText(obj, "GrpText/Text_SuitName")
      duty.transIcon = UIUtils.GetRectTransform(obj, "Trans_GrpElement")
      duty.imgIcon = UIUtils.GetImage(obj, "Trans_GrpElement/ImgIcon")
      duty.type = data.id
      duty.grpset = obj.transform:Find("GrpSel")
      duty.imgIcon.sprite = IconUtils.GetGunTypeIcon(data.icon .. "_W")
      duty.txtName.text = data.id == 0 and TableData.GetHintById(101006) or data.name.str
      setactive(duty.transIcon, true)
      UIUtils.GetButtonListener(duty.btnSort.gameObject).onClick = function()
        self:OnClickElement(duty)
      end
      table.insert(self.dutyList, duty)
    end
  end
  UIUtils.GetUIBlockHelper(self.parentPanel.mView.mUIRoot, self.mTrans_DutyContent, function()
    self:CloseElement()
  end)
  self.curDuty = self.dutyList[1]
  for i = 1, #self.dutyList do
    if self.dutyList[i] ~= self.curDuty then
      self.dutyList[i].txtName.color = self.textcolor.BeforeSelected
      setactive(self.dutyList[i].grpset, false)
    else
      self.dutyList[i].txtName.color = self.textcolor.AfterSelected
      setactive(self.dutyList[i].grpset, true)
    end
  end
end

function UISupportGunItem:InitSortContent()
  if self.sortContent == nil then
    self.sortContent = UIGunSortItem.New()
    self.sortContent:InitCtrl(self.mTrans_SortContent)
    UIUtils.GetButtonListener(self.sortContent.mBtn_Sort.gameObject).onClick = function()
      self:OnClickSortList()
    end
    UIUtils.GetButtonListener(self.sortContent.mBtn_Ascend.gameObject).onClick = function()
      self:OnClickAscend()
    end
  end
  local sortList = self:InstanceUIPrefab("UICommonFramework/ComScreenDropdownListItemV2.prefab", self.mTrans_SortList)
  local parent = UIUtils.GetRectTransform(sortList, "Content")
  for i = 1, 3 do
    local obj = self:InstanceUIPrefab("Character/ChrEquipSuitDropdownItemV2.prefab", parent)
    if obj then
      local sort = {}
      sort.obj = obj
      sort.btnSort = UIUtils.GetButton(obj)
      sort.txtName = UIUtils.GetText(obj, "GrpText/Text_SuitName")
      sort.sortType = i
      sort.hintID = 101000 + i
      sort.sortCfg = FacilityBarrackGlobal.GunSortCfg[i]
      sort.isAscend = false
      sort.grpset = obj.transform:Find("GrpSel")
      sort.txtName.text = TableData.GetHintById(sort.hintID)
      self.textcolor = obj.transform:GetComponent("TextImgColor")
      self.beforecolor = self.textcolor.BeforeSelected
      self.aftercolor = self.textcolor.AfterSelected
      self.imgbeforecolor = self.textcolor.ImgBeforeSelected
      self.imgaftercolor = self.textcolor.ImgAfterSelected
      UIUtils.GetButtonListener(sort.btnSort.gameObject).onClick = function()
        self:OnClickSort(sort.sortType)
      end
      table.insert(self.sortList, sort)
    end
  end
  UIUtils.GetUIBlockHelper(self.parentPanel.mView.mUIRoot, self.mTrans_SortList, function()
    self:CloseItemSort()
  end)
  self.curSort = self.sortList[FacilityBarrackGlobal.GunSortType.Time]
  self.curSort.isAscend = true
end
