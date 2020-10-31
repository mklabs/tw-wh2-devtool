require("console");
require("remove_component");
require("ui/ComponentMixin");

local json = require("vendors/json");

OptionsTabComponent = {
    frameName = "DevToolOptionsTabComponent",
    devtool = nil,
    component = nil,
    content = nil,
    codeOutputLabel = nil,
    codeOutputTextbox = nil,
    formFields = {},
    listeners = {}
};

function OptionsTabComponent:new(devtool)
    self.devtool = devtool;
    self:loadOptionsFromFile("devtool_options.json");
    self:createFrame();
    self:createComponents();
    return self;
end;

function OptionsTabComponent:createFrame()
    local component = self.devtool.component;
    local content = self.devtool.content;

    component:CreateComponent(self.frameName, "UI/campaign ui/script_dummy");
    self.component = find_uicomponent(component, self.frameName);
    self.component:PropagatePriority(component:Priority());
    component:Adopt(self.component:Address());

    self:resizeComponent(self.component, content:Width(), content:Height());
    self:positionComponentRelativeTo(self.component, content, 0, 0);

    -- create main parchment with title / and box
    self.component:CreateComponent("clanPanel_UITEMP", "ui/campaign ui/clan");
    local clan = find_uicomponent(self.component, "clanPanel_UITEMP");

    local traitPanel = find_uicomponent(clan, "main", "tab_children_parent", "Summary", "portrait_frame", "parchment_L", "trait_panel");
    traitPanel:PropagatePriority(self.component:Priority());
    self.component:Adopt(traitPanel:Address());
    remove_component(clan);

    self:resizeComponent(traitPanel, content:Width() - 50, content:Height() - 200);
    self:positionComponentRelativeTo(traitPanel, content, 25, 50);

    local heading = find_uicomponent(traitPanel, "parchment_divider_title", "heading_traits");
    heading:SetStateText("Options");

    self.content = traitPanel;
end;

function OptionsTabComponent:createComponents()
    self:createForm();
end;

function OptionsTabComponent:createForm(fieldName, labelText, tooltipText)
    self:createFormRow(
        "codeOutput",
        "Path to code output: ",
        "Path to the code output to which a file will be created relative to Total War WARHAMMER II folder. It will contain the code you input and execute in the devtool.\n\nLeave it blank to disable the option."
    );

    self:createFormRow(
        "logsOutput",
        "Path to logs output: ",
        "Path to the logs output to which a file will be created relative to Total War WARHAMMER II folder. It will contain the text content you see below the console textbox, with executed code, print outputs and return result.\n\nLeave it blank to disable the option."
    );
end;

function OptionsTabComponent:createFormRow(fieldName, labelText, tooltipText)
    local content = self.content;
    local componentName = self.frameName .. "_" .. fieldName;
    tooltipText = tooltipText or "";
    
    -- Label
    content:CreateComponent(componentName .. "_UITEMP", "ui/campaign ui/mission_details");
    local tempUI = UIComponent(content:Find(componentName .. "_UITEMP"));
    local label = find_uicomponent(tempUI, "mission_details_child", "description_background", "description_view", "dy_description");

    content:Adopt(label:Address());
    label:PropagatePriority(content:Priority());
    remove_component(tempUI);

    local textWidth, textHeight = label:TextDimensionsForText(labelText);
    self:resizeComponent(label, textWidth, textHeight);

    local lastField = self.formFields[#self.formFields];
    local lastFieldX, lastFieldY = 0, 50;
    if lastField then
        lastFieldX, lastFieldY = lastField.field:Position();
    end
    self:positionComponentRelativeTo(label, content, 0, lastFieldY);

    label:SetStateText(labelText);
    label:SetTooltipText(tooltipText, true);

    -- Field
    local fieldComponentName = componentName .. "_TextBox";
    content:CreateComponent(fieldComponentName .. "_UITEMP", "ui/common ui/file_requester");
    local tempFieldUI = UIComponent(content:Find(fieldComponentName .. "_UITEMP"));
    local textbox = find_uicomponent(tempFieldUI, "input_name");
    
    textbox:PropagatePriority(content:Priority());
    content:Adopt(textbox:Address());
    remove_component(find_uicomponent(textbox, "input_name_label"));
    remove_component(tempFieldUI);

    -- set value from saved value
    local savedValue = self.optionsData[fieldName] or "";
    textbox:SimulateLClick();
    for i in string.gmatch(savedValue, ".") do
        textbox:SimulateKey(i);
    end
    textbox:SetTooltipText(tooltipText, true);

    local contentWidth, contentHeight = content:Bounds();
    self:resizeComponent(textbox, contentWidth - 20);
    self:positionComponentRelativeTo(textbox, label, 10, label:Height());

    table.insert(self.formFields, {
        fieldName = fieldName,
        label = label,
        field = textbox        
    });
end;

function OptionsTabComponent:getFormData()
    local data = {};

    for i=1, #self.formFields do
        local formField = self.formFields[i];
        data[formField.fieldName] = formField.field:GetStateText();
    end;

    return data;
end;

function OptionsTabComponent:loadOptionsFromFile(filepath)
    console.log("Loading values from file: " .. filepath);
    local file = io.open(filepath, "r");
    if file then
        local content = file:read("*all");
        local data = json.decode(content);
        self.optionsData = data;
        file:close();
    else 
        self.optionsData = {};
    end;
end;

function OptionsTabComponent:removeFrame()
    remove_component(self.component);
    for i, listener in ipairs(self.listeners) do
        core:remove_listener(listener);
    end

    self.listeners = {};
end;

function OptionsTabComponent:hideFrame()
    self.component:SetVisible(false);
end;

function OptionsTabComponent:showFrame()
    self.component:SetVisible(true);
end;

includeMixins(OptionsTabComponent, ComponentMixin);