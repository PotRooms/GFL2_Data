require("UI.UIBaseCtrl")
require("UI.Common.UICommonItem")
require("UI.ActivityPanel.Item.UIActivityItemBase")
require("UI.SimpleMessageBox.SimpleMessageBoxPanel")
UIActivityAmoWishItem = class("UIActivityAmoWishItem", UIActivityItemBase)
UIActivityAmoWishItem.__index = UIActivityAmoWishItem
local basePath = "Activity/AmoWish/"
local pictureName = {
  "/Img_AmoWishActivity_Chr1",
  "/Img_AmoWishActivity_Chr2",
  "/Img_AmoWishActivity_Chr3",
  "/Img_AmoWishActivity_Chr4",
  "/Img_AmoWishActivity_Chr5",
  "/Img_AmoWishActivity_Chr6"
}

function UIActivityAmoWishItem:OnInit()
  self.mUIRewardList = {}
  self.mRedPointObj = self:InstanceUIPrefab("UICommonFramework/ComRedPointItemV2.prefab", self.ui.mScrollItem_RedPoint, true)
end

function UIActivityAmoWishItem:OnShow()
  self.ui.mText_TextAcName.text = self.mActivityTableData.name.str
  UIUtils.GetButtonListener(self.ui.mBtn_Detail.gameObject).onClick = function()
    SimpleMessageBoxPanel.ShowByParam(TableData.GetHintById(260220), self.mActivityTableData.help.str)
  end
  local planActivityData = TableData.listActivityListDatas:GetDataById(self.mActivityTableData.id)
  if planActivityData == nil then
    return
  end
  self.ui.mText_Time:StartCountdown(self.mCloseTime)
  self.ui.mTextFit_Info.text = self.mActivityTableData.desc.str
  if self.mRewardTable ~= nil then
    for _, v in pairs(self.mRewardTable) do
      gfdestroy(v:GetRoot())
    end
  end
  self.mRewardTable = {}
  if self.mActivityTableData.reward_show ~= nil and self.mActivityTableData.reward_show ~= "" then
    local index = 1
    local rewards = string.split(self.mActivityTableData.reward_show, ",")
    for k, v in pairs(rewards) do
      local item = self.mRewardTable[index]
      if item == nil then
        item = UICommonItem.New()
        item:InitCtrl(self.ui.mSListChild_Content)
        table.insert(self.mRewardTable, item)
      end
      local itemData = TableData.GetItemData(tonumber(v))
      item:SetItemByStcData(itemData, 0)
      index = index + 1
    end
  end
  local amoActivityId = self.mActivityID
  UIUtils.GetButtonListener(self.ui.mBtn_Goto.gameObject).onClick = function()
    if self.mCloseTime < CGameTime:GetTimestamp() then
      UIUtils.PopupHintMessage(260044)
      return
    end
    NetCmdActivityAmoData:SendGetActivityAmo(function(ret)
      if ret ~= ErrorCodeSuc then
        return
      end
      NetCmdActivityAmoData.SelectId = -1
      UIManager.OpenUIByParam(UIDef.UIActivityAimoWishPanel, {
        plan = planActivityData,
        close = self.mCloseTime
      })
    end)
  end
  local redPoint = NetCmdActivityAmoData:CheckHasRedPoint(amoActivityId)
  setactive(self.ui.mScrollItem_RedPoint, 0 < redPoint)
  self:InitPicture()
end

function UIActivityAmoWishItem:InitPicture()
  local activityData = TableDataBase.listAmoActivityMainDatas:GetDataById(self.mActivityTableData.id)
  local folder = activityData.main_bg
  for i = 1, 6 do
    self.ui["mImg_ImgChr" .. i].sprite = IconUtils.GetActivitySprite(basePath .. folder .. pictureName[i])
  end
end

function UIActivityAmoWishItem:OnHide()
  for _, v in pairs(self.mRewardTable) do
    gfdestroy(v:GetRoot())
  end
  gfdestroy(self.mRedPointObj)
  self.ui.mSListChild_Content.transform.localPosition = vectorzero
end

function UIActivityAmoWishItem:RefreshList()
end

function UIActivityAmoWishItem:OnTop()
  local redPoint = NetCmdActivityAmoData:CheckHasRedPoint(self.mActivityID)
  setactive(self.ui.mScrollItem_RedPoint, 0 < redPoint)
end

function UIActivityAmoWishItem:OnClose()
  for _, v in pairs(self.mRewardTable) do
    gfdestroy(v:GetRoot())
  end
end
