for _, s in pairs(storage.settings) do
    if s.trash_not_requested == nil then
        s.trash_not_requested = false
    end
    if s.request_from_buffers == nil then
        s.request_from_buffers = true
    end
end
