function unpack ( t )    
    local new = table.remove(t, 1)
    if new then    
        return new, unpack(t)
    end
end

return unpack