require("UI.UIBaseCtrl")
UIActivityStoreRecordItem = class("UIActivityStoreRecordItem", UIBaseCtrl)
UIActivityStoreRecordItem.__index = UIActivityStoreRecordItem

function UIActivityStoreRecordItem:__InitCtrl()
  self.mImg_Icon = self:GetImage("GrpType/ImgIcon/Img_Icon")
  self.mText_Name = self:GetText("GrpType/Text_Type")
  self.mText_Reward = self:GetText("GrpReward/Text_Reward")
  self.mText_Time = self:GetText("GrpTime/Text_Time")
end

function UIActivityStoreRecordItem:InitCtrl(root)
  self:SetRoot(root)
  self:__InitCtrl()
end

function UIActivityStoreRecordItem:InitData(data)
  local boxData = TableData.listCollectionActivityBoxDatas:GetDataById(data.Id)
  if boxData ~= nil then
    self.mImg_Icon.sprite = IconUtils.GetItemSprite(boxData.icon)
    self.mText_Name.text = boxData.name
    local rewardStr = {}
    if boxData.args_1 ~= nil then
      for id, num in pairs(boxData.args_1) do
        local itemData = TableData.GetItemData(id)
        table.insert(rewardStr, itemData.name.str .. "\195\151" .. num)
      end
    end
    for id, num in pairs(boxData.args) do
      if id == data.ItemId then
        local itemData = TableData.GetItemData(data.ItemId)
        table.insert(rewardStr, itemData.name.str .. "\195\151" .. num)
        break
      end
    end
    if 0 < #rewardStr then
      if #rewardStr == 1 then
        self.mText_Reward.text = rewardStr[1]
      elseif #rewardStr == 2 then
        self.mText_Reward.text = rewardStr[1] .. "\n" .. rewardStr[2]
      end
    end
    self.mText_Time.text = CS.CGameTime.ConvertLongToDateTime(data.Gettime):ToString("yyyy.MM.dd")
  else
    gferror(data.Id .. ": \229\174\157\231\174\177\232\161\168\230\156\170\230\137\190\229\136\176\229\175\185\229\186\148\230\149\176\230\141\174!")
  end
end
