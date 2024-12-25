require("UI.UIBaseCtrl")
Btn_ArchivesCenterChrPlotItemV2 = class("Btn_ArchivesCenterChrPlotItemV2", UIBaseCtrl)
Btn_ArchivesCenterChrPlotItemV2.__index = Btn_ArchivesCenterChrPlotItemV2

function Btn_ArchivesCenterChrPlotItemV2:ctor(root)
end

function Btn_ArchivesCenterChrPlotItemV2:InitCtrl(parent)
  local itemPrefab = parent:GetComponent(typeof(CS.ScrollListChild))
  local instObj = instantiate(itemPrefab.childItem)
  self.ui = {}
  self:LuaUIBindTable(instObj, self.ui)
  self.ui.mAnimator_ArchivesCenterChrPlotItemV2.keepAnimatorControllerStateOnDisable = true
  if parent then
    UIUtils.AddListItem(instObj.gameObject, parent.gameObject)
  end
  self.rootGO = instObj
  self:SetRoot(instObj.transform)
end

function Btn_ArchivesCenterChrPlotItemV2:OnClickPlotIndex(data, index)
  if self.parent.currSelectIndex == index then
    return
  end
  self.parent.ui.mAnimator_Root:SetBool("Switch", true)
  local state = NetCmdArchivesData:GetSingleCharacterPlotState(data.id)
  self.parent.currSelectIndex = index
  self.parent.ui.mText_Num.text = "0" .. index
  self.parent.ui.mText_PlotName.text = data.name.str
  setactive(self.parent.ui.mTrans_ImgLock.gameObject, state == 0)
  setactive(self.parent.ui.mTrans_ImgStart.gameObject, 0 < state)
  setactive(self.parent.ui.mTrans_RedPoint.gameObject, false)
  if state == 0 then
    self.parent.ui.mText_Info.text = data.text.str
  else
    self.parent.ui.mText_Info.text = TableData.GetHintById(110050)
  end
  if self.parent.ui.mText_RewardNum then
    local itemId, itemNum
    for i, v in pairs(data.reward) do
      itemId = i
      itemNum = v
    end
    if itemId and itemNum then
      self.parent.ui.mImg_RewardIcon.sprite = IconUtils.GetItemIconSprite(itemId)
      self.parent.ui.mText_RewardNum.text = itemNum
    end
  end
  setactive(self.parent.ui.mTrans_Read.gameObject, state == 1)
  setactive(self.parent.ui.mTrans_Unread.gameObject, state ~= 1 and 0 < data.reward.Count)
  self.parent:UpdateBtnState()
end

function Btn_ArchivesCenterChrPlotItemV2:SetData(data, index, parent)
  self.ui.mText_Text.text = "0" .. index
  if self.parent == nil then
    self.parent = parent
  end
  self.itemIndex = index
  local state = NetCmdArchivesData:GetSingleCharacterPlotState(data.id)
  local gunID = self.parent.data.unit_id[0]
  local showRedDot = 0 < NetCmdLoungeData:DormChrStoryRedPointByGunID(gunID)
  setactive(self.ui.mTrans_RedPoint.gameObject, false)
  setactive(self.ui.mTrans_ImgLock.gameObject, state == 0)
  UIUtils.GetButtonListener(self.ui.mBtn_Item.gameObject).onClick = function()
    self:OnClickPlotIndex(data, index)
  end
end

function Btn_ArchivesCenterChrPlotItemV2:UpdateParentSatte(isShow)
  setactive(self.rootGO.gameObject, isShow)
end
