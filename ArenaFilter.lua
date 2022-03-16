local ADDON_NAME = ...
local AF_LFG_LIST_CATEGORY_ARENAS = 4;

local function AF_IsArenaGroupFinder()
    return LFGListFrame.SearchPanel.categoryID == AF_LFG_LIST_CATEGORY_ARENAS
end

local function AF_CanChangeLanguages()
	local availableLanguages = C_LFGList.GetAvailableLanguageSearchFilter()
    local defaultLanguages = C_LFGList.GetDefaultLanguageSearchFilter()

	for i=1, #availableLanguages do
		if not defaultLanguages[availableLanguages[i]] then
			return true
		end
    end

    return false
end

local function AF_AddDropDownMenuTitle(title)
    local entry = UIDropDownMenu_CreateInfo()
    entry.text = title
    entry.hasArrow = false
    entry.isUninteractable = true
    entry.isTitle = true
    entry.isNotRadio = true
    entry.notCheckable = true
    UIDropDownMenu_AddButton(entry)
end

local function AF_FilterResultList()
    if not AF_IsArenaGroupFinder() then
        return
    end

    local panel = LFGListFrame.SearchPanel

    LFGListSearchPanel_UpdateResultList(panel)

    local updated = false

    for i = #panel.results, 1, -1 do
        local resultID = panel.results[i]
        local searchResultInfo = C_LFGList.GetSearchResultInfo(resultID)
        local hasClassOrRole = false
        for j=1, searchResultInfo.numMembers do
            local role, class = C_LFGList.GetSearchResultMemberInfo(resultID, j)
            if ArenaFilter_Classes[class] ~= false and ArenaFilter_Roles[role] ~= false then
                hasClassOrRole = true
                break
            end
        end

        if hasClassOrRole == false then
            tremove(panel.results, i)
            updated = true
        end
    end

    if updated then
        LFGListSearchPanel_UpdateResults(panel)
    end
end

local function AF_AddDropDownMenuOptions(storage, options)
    for key, label in pairs(options) do
        local entry = UIDropDownMenu_CreateInfo()
        entry.text = label
        entry.checked = storage[key] ~= false
        entry.disabled = false
        entry.isNotRadio = true
        entry.keepShownOnClick = true
        entry.func = function(_, _, _, checked)
            storage[key] = checked
            AF_FilterResultList()
        end
        UIDropDownMenu_AddButton(entry)
    end
end

local function AF_AddDropDownMenuClasses()
    local options = {}
    for i=1, #CLASS_SORT_ORDER do
        local className, classFile = GetClassInfo(i)
        options[classFile] = className
    end

    AF_AddDropDownMenuOptions(ArenaFilter_Classes, options)
end

local function AF_AddDropDownMenuRoles()
    local options = {
        TANK = _G["TANK"],
        DAMAGER = _G["DAMAGER"],
        HEALER = _G["HEALER"]
    }

    AF_AddDropDownMenuOptions(ArenaFilter_Roles, options)
end

local function AF_InitializeLanguageFilter(dropdown)
    -- Preserve original behavior, but only if language filter is expected to
    -- be shown.
    if AF_CanChangeLanguages() then
        AF_AddDropDownMenuTitle(_G["LANGUAGE"])
        LFGListUtil_InitializeLangaugeFilter(dropdown)
    end

    AF_AddDropDownMenuTitle(_G["CLASS"])
    AF_AddDropDownMenuClasses()

    AF_AddDropDownMenuTitle(_G["ROLE"])
    AF_AddDropDownMenuRoles()
end

local function AF_LFGListSearchPanel_OnShow(self)
    -- Preserve original behavior.
    LFGListSearchPanel_OnShow(self)

    if AF_IsArenaGroupFinder() then
        -- Override dropdown initializer if viewing arena group finder.
        UIDropDownMenu_SetInitializeFunction(
            LFGListLanguageFilterDropDownFrame,
            AF_InitializeLanguageFilter
        )

        -- Default behavior may hide filter button. Ensure it's shown.
        LFGListFrame.SearchPanel.SearchBox:SetWidth(228)
        LFGListFrame.SearchPanel.FilterButton:Show()

        -- Reapply filtering.
        AF_FilterResultList()
    else
        -- Reset dropdown initializer to default to other group finder.
        UIDropDownMenu_SetInitializeFunction(
            LFGListLanguageFilterDropDownFrame,
            LFGListUtil_InitializeLangaugeFilter
        )
    end
end

local function AF_InitializeSavedVariables()
    if not ArenaFilter_Classes then
        ArenaFilter_Classes = {}
    end

    if not ArenaFilter_Roles then
        ArenaFilter_Roles = {}
    end
end

local AF = CreateFrame("Frame")

local function AF_OnEvent(_, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == ADDON_NAME then
            AF_InitializeSavedVariables()
            LFGListFrame.SearchPanel:SetScript("OnShow", AF_LFGListSearchPanel_OnShow)
            AF:UnregisterEvent("ADDON_LOADED")
        end
    elseif event == "LFG_LIST_SEARCH_RESULTS_RECEIVED" then
        AF_FilterResultList()
    end
end

AF:RegisterEvent("ADDON_LOADED")
AF:RegisterEvent("LFG_LIST_SEARCH_RESULTS_RECEIVED")
AF:SetScript("OnEvent", AF_OnEvent)
