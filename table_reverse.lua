function table_reverse ( t )  
    local new_t = {}

    if (type(t) ~= 'table') then
        error('Error: incorrect value for table reverse')
    end

    if #t == 0 then return t end

    for i = #t, 1, -1 do
        table.insert(new_t, t[i]) 
    end

    return new_t
end

return table_reverse