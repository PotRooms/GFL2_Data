require("UI.Tips.UITipsPanel")
require("UI.Repository.UIRepositoryGlobal")
TipsManager = {}
local this = TipsManager

function TipsManager.Add(gameObject, param, paramData, paramData2, paramData3, paramData4, paramData5, paramData6, paramData7, paramData8, paramData9, paramData10)
  local click = UIUtils.GetButtonListener(gameObject)
  click.param = param
  click.paramData = {
    paramData,
    paramData2,
    paramData3,
    paramData4,
    paramData5,
    paramData6,
    paramData7,
    paramData8,
    paramData9,
    paramData10
  }
  click.onClick = TipsManager.OnItemClick
end

function TipsManager.OnItemClick(gameObject)
  if gameObject ~= nil then
    local click = getcomponent(gameObject, typeof(CS.ButtonEventTriggerListener))
    if click ~= nil then
      local item = click.param
      local num = click.paramData[1] or 0
      local needGetWay = click.paramData[2] or false
      local showTime = click.paramData[3] or false
      local relateId = click.paramData[4] or 0
      local opencallback = click.paramData[5]
      local closecallback = click.paramData[6]
      local showWeaponPartTips = click.paramData[7] or false
      local showCreditCount = click.paramData[8] or false
      local hideCompose = click.paramData[9] or false
      local showUse = click.paramData[10] or false
      if item ~= nil then
        if opencallback then
          opencallback()
        end
        if item.type == GlobalConfig.ItemType.GunType then
          CS.RoleInfoCtrlHelper.Instance:InitSysPlayerDataById(item.id)
        else
          TipsPanelHelper.OpenUITipsPanel(item, num, needGetWay, showTime, relateId, closecallback, showWeaponPartTips, false, showCreditCount, false, hideCompose, showUse)
        end
      end
    end
  end
end

function TipsManager.ShowStaminaTips()
  local storeData = NetCmdStoreData:GetStoreGoodById(1)
  if storeData.remain_times > 0 then
    local prizeData = storeData.ItemAndNum
    local title = TableData.GetHintById(208)
    local hint = string_format(TableData.GetHintById(201), storeData.price, prizeData[0].num, storeData.remain_times)
    MessageBox.Show(title, hint, TableData.GetHintById(20), TableData.GetHintById(19), nil, function()
      UIManager.OpenUIByParam(UIDef.UICommonGetPanel)
    end)
  else
    local title = TableData.GetHintById(208)
    local hint = TableData.GetHintById(203)
    MessageBox.ShowMidBtn(title, hint, TableData.GetHintById(18), nil, nil)
  end
end

function TipsManager.CheckStaminaIsEnough(needStamina, needPopupString)
  if needPopupString == nil then
    needPopupString = true
  end
  local playerStamina = GlobalData.GetStaminaResourceItemCount(GlobalConfig.StaminaId)
  if needStamina > playerStamina then
    if needPopupString then
      local hint = GlobalConfig.GetCostNotEnoughStr(GlobalConfig.StaminaId)
      CS.PopupMessageManager.PopupString(hint)
    end
    UIManager.OpenUIByParam(UIDef.UICommonGetPanel)
    return false
  end
  return true
end

function TipsManager.CheckStaminaIsEnough2(needStamina)
  local playerStamina = GlobalData.GetStaminaResourceItemCount(GlobalConfig.StaminaId)
  if needStamina > playerStamina then
    UIManager.OpenUIByParam(UIDef.UICommonGetPanel)
    return false
  end
  return true
end

function TipsManager.CheckTicketIsEnough(needTicket, TicketItemId)
  local playerTicket = 0
  if TicketItemId ~= nil then
    local itemdata = NetCmdItemData:GetItemCmdData(TicketItemId)
    if itemdata ~= nil then
      playerTicket = itemdata.Num
    end
    if needTicket > playerTicket then
      local hint = string_format(TableData.GetHintById(194006), TableData.listItemDatas:GetDataById(TicketItemId).name.str)
      CS.PopupMessageManager.PopupString(hint)
      return false
    end
  end
  return true
end

function TipsManager.CheckStaminaIsEnoughOnly(needStamina)
  local playerStamina = GlobalData.GetStaminaResourceItemCount(GlobalConfig.StaminaId)
  if needStamina > playerStamina then
    local itemData = TableData.listItemDatas:GetDataById(101)
    local hint = string_format(TableData.GetHintById(200), itemData.name.str)
    local title = TableData.GetHintById(64)
    TipsManager.ShowBuyStamina()
    MessageBoxPanel.IsQuickClose = true
    return false
  end
  return true
end

function TipsManager.ShowBuyStamina()
  if TipsManager.NeedLockTips(27000) then
    return
  end
  TimerSys:DelayCall(0.5, function(obj)
    UIManager.OpenUIByParam(UIDef.UICommonGetPanel)
  end)
end

function TipsManager.CheckTrainingCountIsEnough()
  local count = NetCmdItemData:GetResItemCount(GlobalConfig.TrainingTicket)
  if count <= 0 then
    local hint = GlobalConfig.GetCostNotEnoughStr(GlobalConfig.TrainingTicket)
    CS.PopupMessageManager.PopupString(hint)
    return false
  end
  return true
end

function TipsManager.NeedLockTips(type)
  if type == 0 or type == nil then
    return false
  end
  if not AccountNetCmdHandler:CheckSystemIsUnLock(type) then
    local lockInfo = TableData.GetUnLockInfoByType(type)
    if lockInfo then
      local unlockTime = CS.CGameTime.ConvertLongToDateTime(lockInfo.OpenDetail)
      local nowTime = CS.CGameTime.ConvertUintToDateTime(CGameTime:GetTimestamp())
      local baseStr = TableData.listHintDatas:GetDataById(903320)
      local str
      if lockInfo.OpenDetail and 0 < lockInfo.OpenDetail and 0 > DateTime.Compare(nowTime, unlockTime) then
        local num = 0
        if unlockTime.Day > nowTime.Day then
          str = TableData.listHintDatas:GetDataById(53)
          num = unlockTime.Day - nowTime.Day
        elseif unlockTime.Hour > nowTime.Hour then
          str = TableData.listHintDatas:GetDataById(52)
          num = unlockTime.Hour - nowTime.Hour
        elseif unlockTime.Minute > nowTime.Minute then
          str = TableData.listHintDatas:GetDataById(51)
          num = unlockTime.Minute - nowTime.Minute
        end
        str = string_format(baseStr, str, num)
      else
        str = UIUtils.CheckUnlockPopupStr(lockInfo)
      end
      CS.PopupMessageManager.PopupString(str)
    end
    MessageSys:SendMessage(GuideEvent.OnSystemIsLocked, nil)
    return true
  end
  return false
end

function TipsManager.CheckItemIsOverflow(itemId, count, needShowMessage)
  count = count == nil and 0 or count
  needShowMessage = needShowMessage == nil and true or needShowMessage
  local itemData = TableData.GetItemData(itemId)
  if itemData then
    local maxCount = 0
    local maxLimit = TableData.listItemLimitDatas:GetDataById(itemId, true)
    if maxLimit then
      maxCount = maxLimit.max_limit
    else
      local type = itemData.type
      local typeData = TableData.listItemTypeDescDatas:GetDataById(type)
      if typeData.related_item and 0 < typeData.related_item then
        local maxLimit = NetCmdItemData:GetItemCountById(typeData.related_item)
        maxCount = maxLimit
      else
        maxCount = typeData.max_limit
      end
    end
    if maxCount <= 0 then
      return false
    else
      local ownCount = NetCmdItemData:GetItemCountById(itemId)
      if maxCount < ownCount + count then
        if needShowMessage then
          local hint = TableData.GetHintById(30009)
          MessageBoxPanel.ShowSingleType(string_format(hint, itemData.name.str))
        end
        return true
      else
        return false
      end
    end
  end
  return false
end

function TipsManager.CheckItemIsOverflowAndStop(itemId, count, limitCount, isInMail)
  if itemId == 0 then
    return false
  end
  count = count == nil and 1 or count
  limitCount = limitCount == nil and 0 or limitCount
  local t = {}
  t[itemId] = count
  local r = TipsManager.CheckItemIsOverflowAndStopByList(t, limitCount, isInMail)
  return r
end

function TipsManager.CheckItemIsOverflowAndStopByList(list, limitCount, isInMail)
  limitCount = limitCount == nil and 0 or limitCount
  local dropList = {}
  for itemId, num in pairs(list) do
    local itemData = TableData.GetItemData(itemId)
    local isPackages = itemData.type == GlobalConfig.ItemType.Packages or itemData.type == GlobalConfig.ItemType.Random and isInMail == false
    if isPackages == true then
      local dropTypeList = {}
      if 0 < itemData.args.Count then
        local dropData = TableData.listDropPackageDatas:GetDataById(itemData.args[0])
        if dropData then
          for i = 0, dropData.args.Count - 1 do
            local arg = dropData.args[i]
            local args = string.split(arg, ":")
            local dropItemID = tonumber(args[1])
            local itemData = TableData.GetItemData(dropItemID)
            if itemData and itemData.type ~= GlobalConfig.ItemType.Packages then
              local maxLimit = TableData.listItemLimitDatas:GetDataById(itemId, true)
              local itemType = itemData.type
              if maxLimit == nil and dropTypeList[itemType] == nil then
                dropTypeList[itemType] = 1
                local dropItemNum = tonumber(args[2]) * num
                if dropList[dropItemID] ~= nil then
                  dropList[dropItemID] = dropList[dropItemID] + dropItemNum
                else
                  dropList[dropItemID] = dropItemNum
                end
              end
            end
          end
        end
        list[itemId] = nil
      end
    end
  end
  for itemId, num in pairs(dropList) do
    if list[itemId] ~= nil then
      list[itemId] = list[itemId] + num
    else
      list[itemId] = num
    end
  end
  local thisTypeItemAllNum = {}
  for itemId, num in pairs(list) do
    local itemData = TableData.GetItemData(itemId)
    local isPackages = itemData.type == GlobalConfig.ItemType.Packages or itemData.type == GlobalConfig.ItemType.Random and isInMail == false
    if itemData and isPackages == false then
      local maxCount = 0
      local typeData
      local maxLimit = TableData.listItemLimitDatas:GetDataById(itemId, true)
      local itemType = itemData.type
      typeData = TableData.listItemTypeDescDatas:GetDataById(itemType)
      if maxLimit then
        if maxLimit.max_limit ~= 0 then
          maxCount = maxLimit.max_limit
        end
      elseif typeData.related_item and 0 < typeData.related_item then
        local maxLimit = NetCmdItemData:GetItemCountById(typeData.related_item)
        maxCount = maxLimit
      else
        maxCount = typeData.max_limit
      end
      if maxCount <= 0 then
      else
        do
          local ownCount = NetCmdItemData:GetItemCountById(itemId, true)
          if itemType == GlobalConfig.ItemType.Weapon then
            ownCount = NetCmdWeaponData:GetWeaponList().Count
          elseif itemType == GlobalConfig.ItemType.WeaponPart then
            ownCount = NetCmdWeaponPartsData:GetAllMods().Count
          end
          if typeData.pile == 0 then
            if thisTypeItemAllNum[itemType] == nil then
              thisTypeItemAllNum[itemType] = num
            else
              thisTypeItemAllNum[itemType] = thisTypeItemAllNum[itemType] + num
            end
          end
          local trueNum = 0
          if typeData.pile == 1 then
            trueNum = num
          else
            trueNum = thisTypeItemAllNum[itemType]
          end
          if maxCount < ownCount + trueNum + limitCount then
            local message1OKFunc
            if typeData ~= nil then
              local itemName = ""
              if typeData.pile == 1 then
                itemName = itemData.name.str
              else
                itemName = typeData.overflow_name.str
              end
              local hint = string_format(TableData.GetHintById(901066), itemName)
              if 0 < typeData.jump then
                function message1OKFunc()
                  UISystem:JumpByID(typeData.jump)
                end
                
                MessageBox.Show(TableData.GetHintById(64), hint, TableData.GetHintById(20), TableData.GetHintById(19), nil, message1OKFunc)
              else
                MessageBox.Show(TableData.GetHintById(64), hint, TableData.GetHintById(18), nil, CS.MessageBox.ShowFlag.eMidBtn)
              end
            end
            return true
          end
        end
      end
    end
  end
  return false
end

function TipsManager.CheckCanRaid(stageData)
  if not stageData then
    return
  end
  local canRiad = AFKBattleManager:CheckCanRaid(stageData)
  if not canRiad then
    if stageData.CanRaid == 1 then
      if stageData.type == CS.LuaUtils.EnumToInt(StageType.CashStage) then
        local gradeId = NetCmdStageRatingData:GetMinGradeIdForRaidOpen(stageData.id)
        local gradeShowData = TableDataBase.listGradeShowDatas:GetDataById(gradeId)
        local hint = TableData.GetHintById(103138, gradeShowData.grade_name.str)
        CS.PopupMessageManager.PopupString(hint)
        return
      end
      local hint = TableData.GetHintById(103077)
      CS.PopupMessageManager.PopupString(hint)
    elseif stageData.CanRaid == 2 then
      if stageData.type == CS.LuaUtils.EnumToInt(StageType.CashStage) then
        local gradeId = NetCmdStageRatingData:GetMinGradeIdForRaidOpen(stageData.id)
        local gradeShowData = TableDataBase.listGradeShowDatas:GetDataById(gradeId)
        local hint = TableData.GetHintById(103138, gradeShowData.grade_name.str)
        CS.PopupMessageManager.PopupString(hint)
        return
      end
      local hint = TableData.GetHintById(103078)
      CS.PopupMessageManager.PopupString(hint)
    end
  end
  return canRiad
end
