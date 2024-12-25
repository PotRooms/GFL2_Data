require("UI.UIBaseCtrl")
UIDormChrPlayBehaviourItem = class("UIDormChrPlayBehaviourItem", UIBaseCtrl)
UIDormChrPlayBehaviourItem.__index = UIDormChrPlayBehaviourItem

function UIDormChrPlayBehaviourItem:ctor()
end

function UIDormChrPlayBehaviourItem:InitCtrl(itemPrefab)
  if itemPrefab == nil then
    return
  end
  local instObj = instantiate(itemPrefab.childItem, itemPrefab.transform)
  self.ui = {}
  self:LuaUIBindTable(instObj, self.ui)
  UIUtils.AddListItem(instObj.gameObject, itemPrefab.gameObject)
  self:SetRoot(instObj.transform)
  UIUtils.GetButtonListener(self.ui.mBtn_Self.gameObject).onClick = function()
    if self.isUnlock then
      if self.limitCloth then
        PopupMessageManager.PopupString(self.popupStr)
        return
      end
      self.clickFunction(self)
    elseif self.behaviourData.unlock == 1 then
      PopupMessageManager.PopupString(self.popupStr)
    elseif self.behaviourData.unlock == 2 then
      UIManager.OpenUIByParam(UIDef.UIDormChrBuyBehaviourPanel, {
        self.behaviourData,
        function()
          self:PlayUpdateAnim()
        end
      })
    end
  end
end

function UIDormChrPlayBehaviourItem:SetData(id, gunID)
  self.behaviourData = TableData.listDormFormationDatas:GetDataById(id)
  self.gunID = gunID
  self.ui.mText_Name.text = self.behaviourData.name.str
  local iconName = "Item_Icon_DormAct_%s"
  local s = string.format(iconName, self.behaviourData.uiicon)
  self.ui.mImg_Icon.sprite = IconUtils.GetIconV2("Item", s)
  setactive(self.ui.mImg_Bar, false)
  self:UpdateUnlockType()
  self:SetSelectState(false)
end

function UIDormChrPlayBehaviourItem:SetClickFunction(func)
  self.clickFunction = func
end

function UIDormChrPlayBehaviourItem:SetSelectState(isSelect)
  self.isSelect = isSelect
  self.ui.mBtn_Self.interactable = self.isSelect == false
  local stateNum = self.isSelect == false and 3 or 2
  if self.isUnlock == false or self.limitCloth then
    stateNum = 0
  end
  self.ui.mAnimator_Self:SetInteger("Switch", stateNum)
end

function UIDormChrPlayBehaviourItem:StartPlayBehavior()
end

function UIDormChrPlayBehaviourItem:UpdateUnlockType()
  self:UpdateUnlockState()
  local stateNum = self.isUnlock == false and 0 or 3
  self.ui.mAnimator_Self:SetInteger("Switch", stateNum)
  setactive(self.ui.mTrans_GoldConsume, self.isUnlock == false and self.behaviourData.unlock == 2)
  setactive(self.ui.mImg_IconPay, self.isUnlock == true and self.behaviourData.unlock == 2)
end

function UIDormChrPlayBehaviourItem:UpdateUnlockState()
  self.isUnlock = true
  self.limitCloth = false
  if self.behaviourData.unlock == 1 then
    local unlockNum = 0
    if self.behaviourData.type == 2 then
      unlockNum = self.behaviourData.unlock_type
    else
      local tbDataID = self.behaviourData.id
      local dormGeneralData = TableData.listDormGeneralDatas:GetDataById(self.gunID, true)
      if dormGeneralData ~= nil and dormGeneralData.unlockmap:ContainsKey(tbDataID) then
        unlockNum = dormGeneralData.unlockmap[tbDataID]
      end
    end
    if 0 < unlockNum then
      self.isUnlock = NetCmdAchieveData:CheckComplete(unlockNum)
      if self.isUnlock == false then
        self.unlockData = TableData.listAchievementDetailDatas:GetDataById(unlockNum, true)
        self.popupStr = ""
        if self.unlockData then
          self.popupStr = self.unlockData.des.str
        end
      end
    end
  elseif self.behaviourData.unlock == 2 then
    self.isUnlock = NetCmdLoungeData:CheckFormationHasUnlock(self.behaviourData.id)
    if self.isUnlock == false then
      local itemID, itemNum
      for i, v in pairs(self.behaviourData.unlock_item) do
        itemID = i
        itemNum = v
      end
      self.ui.mImg_CostIcon.sprite = IconUtils.GetItemIconSprite(itemID)
      self.ui.mText_CostNum.text = tostring(itemNum)
    end
  end
  if 0 < self.behaviourData.clothes_id and self.behaviourData.clothes_id ~= CS.LoungeModelManager.Instance.curShowModel.GunCmdData.dormCostume then
    self.limitCloth = true
    local clothData = TableData.listClothesDatas:GetDataById(self.behaviourData.clothes_id, true)
    if clothData then
      self.popupStr = string_format(TableData.GetHintById(280026), clothData.name)
    end
  end
end

function UIDormChrPlayBehaviourItem:PlayUpdateAnim()
  self:UpdateUnlockState()
  self.ui.mAnimator_Self:SetInteger("Switch", 1)
end
