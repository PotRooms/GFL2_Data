require("UI.UIBaseView")
UICommonGetView = class("UICommonGetView", UIBaseView)
UICommonGetView.__index = UICommonGetView

function UICommonGetView:ctor()
  self.contentList = {}
end

function UICommonGetView:__InitCtrl()
  self.mBtn_Close = UIUtils.GetTempBtn(self:GetRectTransform("Root/GrpDialog/GrpTop/GrpClose"))
  self.mBtn_BGClose = self:GetButton("Root/GrpBg/Btn_Close")
  self.mBtn_Confirm = UIUtils.GetTempBtn(self:GetRectTransform("Root/GrpDialog/GrpAction/BtnConfirm"))
  self.mBtn_Cancel = UIUtils.GetTempBtn(self:GetRectTransform("Root/GrpDialog/GrpAction/BtnCancel"))
  self.mTextTitle = self:GetText("Root/GrpDialog/GrpCenter/GrpTextTittle/TextName")
  self.mTextInfo = self:GetText("Root/GrpDialog/GrpCenter/GrpTextInfo/Text_Description")
  self.mTrans_PriceDetails = self:GetRectTransform("Root/GrpDialog/GrpCenter/Trans_Btn_PriceDetails")
  self.mImg_PriceDetailsImageIcon = self:GetImage("Root/GrpDialog/GrpCenter/Trans_Btn_PriceDetails/GrpItemIcon/Img_Icon")
  self.mTxt_PriceSetailsNum = self:GetText("Root/GrpDialog/GrpCenter/Trans_Btn_PriceDetails/Text_Num")
  self.mBtn_PriceDetails = UIUtils.GetTempBtn(self:GetRectTransform("Root/GrpDialog/GrpCenter/Trans_Btn_PriceDetails/BtnInfo"))
  self.mTrans_GrpPriceDetails = self:GetRectTransform("Root/GrpDialog/GrpCenter/Trans_GrpPriceDetails")
  self.mTrans_GrpPriceDetailsContent = self:GetRectTransform("Root/GrpDialog/GrpCenter/Trans_GrpPriceDetails/GrpAllSkillDescription/GrpDescribe/Viewport/Content")
  self.mBtn_GrpPriceDetails = UIUtils.GetTempBtn(self:GetRectTransform("Root/GrpDialog/GrpCenter/Trans_GrpPriceDetails/BtnInfo"))
  self.mTxt_TextNum = self:GetText("Root/GrpDialog/GrpCenter/GrpTextInfo/Trans_GrpTextNum/Text_Num")
  self.mTrans_TextNum = self:GetRectTransform("Root/GrpDialog/GrpCenter/GrpTextInfo/Trans_GrpTextNum")
  for i = 1, 2 do
    local obj = self:GetRectTransform("Root/GrpDialog/GrpCenter/GrpItemList/Content/ComItem_" .. i)
    local contetn = self:InitContent(obj, i)
    table.insert(self.contentList, contetn)
  end
end

function UICommonGetView:InitCtrl(root)
  self:SetRoot(root)
  self:__InitCtrl()
end

function UICommonGetView:InitContent(obj, index)
  local content = {}
  local transItem = obj
  content.type = index
  content.item = transItem
  content.imgIcon = UIUtils.GetImage(obj, "GrpItem/Icon")
  content.txtRemainItem = UIUtils.GetText(obj, "GrpQualityNum/GrpText_Num\231\173\137\231\186\167\230\150\135\229\173\151\229\146\140\230\149\176\233\135\143\229\133\177\231\148\168\239\188\136\232\191\152\229\184\166Icon\239\188\137/Text")
  content.transChoose = UIUtils.GetRectTransform(obj, "Trans_ChooseIcon\233\128\137\230\139\169\231\154\132\229\139\190\239\188\136\233\128\154\231\148\168\229\139\190\233\128\137\239\188\137")
  content.tranSel = UIUtils.GetRectTransform(obj, "ImgSel")
  content.imgRank = UIUtils.GetImage(obj, "GrpQualityNum/GrpQualityLine\229\147\129\232\180\168\232\137\178\230\157\161")
  content.btnSelect = CS.LuaUIUtils.GetButton(transItem)
  return content
end
