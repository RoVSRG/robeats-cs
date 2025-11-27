local Grade = {
    SS = 1;
    S = 2;
    A = 3;
    B = 4;
    C = 5;
    D = 6;
    F = 7;
}

local accuracy_to_grade = {
    [Grade.SS] = 100;
    [Grade.S] = 95;
    [Grade.A] = 90;
    [Grade.B] = 80;
    [Grade.C] = 70;
    [Grade.D] = 60;
    [Grade.F] = 50;
}

local accuracy_to_color = {
    [Grade.SS] = Color3.fromRGB(255, 246, 116);
    [Grade.S] = Color3.fromRGB(240, 205, 9);
    [Grade.A] = Color3.fromRGB(99, 238, 18);
    [Grade.B] = Color3.fromRGB(11, 77, 163);
    [Grade.C] = Color3.fromRGB(187, 12, 178);
    [Grade.D] = Color3.fromRGB(221, 17, 17);
    [Grade.F] = Color3.fromRGB(129, 0, 0);
}

function Grade:get_grade_from_accuracy(accuracy)
    for enum_member = 1, #accuracy_to_grade do
        local grade_acc = accuracy_to_grade[enum_member]
        
        if (accuracy >= grade_acc) or (enum_member == Grade.F) then
            local name

            for itr_name, value in pairs(self) do
                if value == enum_member then
                    name = itr_name
                end
            end

            return enum_member, name, accuracy_to_color[enum_member]
        end
    end
end

return Grade
