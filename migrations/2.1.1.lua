for _, s in pairs(storage.settings) do
    if s.clear_assembler_circuits == nil then
        s.clear_assembler_circuits = true
    end
    if s.clear_inserter_circuits == nil then
        s.clear_inserter_circuits = true
    end
end

require('scripts.settings_gui').update_all()
