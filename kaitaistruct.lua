local class = require("class")
local stringstream = require("string_stream")

KaitaiStruct = class.class()

function KaitaiStruct:_init(io)
    self._io = io
end

KaitaiStream = class.class()

function KaitaiStream:_init(io)
    self._io = io
    self:align_to_byte()
end

function KaitaiStream:close()
    self._io:close()
end

--=============================================================================
-- Stream positioning
--=============================================================================

function KaitaiStream:is_eof()
    if self.bits_left > 0 then
        return false
    end
    local current = self:pos()
    local dummy = self:read(1)
    self:seek(current)

    return dummy == nil
end

function KaitaiStream:seek(n)
    self._io:seek("set", n)
end

function KaitaiStream:pos()
    return self._io:seek()
end

function KaitaiStream:size()
    local current = self:pos()
    local size = self._io:seek("end")
    self:seek(current)

    return size
end

--=============================================================================
-- Raw read proxy
--=============================================================================

function KaitaiStream:read(num)
    return self._io:read(num)
end

--=============================================================================
-- Integer numbers
--=============================================================================

-------------------------------------------------------------------------------
-- Signed
-------------------------------------------------------------------------------

function KaitaiStream:read_s1()
    local raw = self:read(1)
    return raw, raw:int()
end

--.............................................................................
-- Big-endian
--.............................................................................

function KaitaiStream:read_s2be()
    local raw = self:read(2)
    return raw, raw:int()
end

function KaitaiStream:read_s4be()
    local raw = self:read(4)
    return raw, raw:int()
end

function KaitaiStream:read_s8be()
    local raw = self:read(8)
    return raw, raw:int64()
end

--.............................................................................
-- Little-endian
--.............................................................................

function KaitaiStream:read_s2le()
    local raw = self:read(2)
    return raw, raw:le_int()
end

function KaitaiStream:read_s4le()
    local raw = self:read(4)
    return raw, raw:le_int()
end

function KaitaiStream:read_s8le()
    local raw = self:read(8)
    return raw, raw:le_int64()
end

-------------------------------------------------------------------------------
-- Unsigned
-------------------------------------------------------------------------------

function KaitaiStream:read_u1()
    local raw = self:read(1)
    return raw, raw:uint()
end

--.............................................................................
-- Big-endian
--.............................................................................

function KaitaiStream:read_u2be()
    local raw = self:read(2)
    return raw, raw:uint()
end

function KaitaiStream:read_u4be()
    local raw = self:read(4)
    return raw, raw:uint()
end

function KaitaiStream:read_u8be()
    local raw = self:read(8)
    return raw, raw:uint64()
end

--.............................................................................
-- Little-endian
--.............................................................................

function KaitaiStream:read_u2le()
    local raw = self:read(2)
    return raw, raw:le_uint()
end

function KaitaiStream:read_u4le()
    local raw = self:read(4)
    return raw, raw:le_uint()
end

function KaitaiStream:read_u8le()
    local raw = self:read(8)
    return raw, raw:le_uint64()
end

--=============================================================================
-- Floating point numbers
--=============================================================================

-------------------------------------------------------------------------------
-- Big-endian
-------------------------------------------------------------------------------

function KaitaiStream:read_f4be()
    local raw = self:read(4)
    return raw, raw:float()
end

function KaitaiStream:read_f8be()
    local raw = self:read(8)
    return raw, raw:float()
end

-------------------------------------------------------------------------------
-- Little-endian
-------------------------------------------------------------------------------

function KaitaiStream:read_f4le()
    local raw = self:read(4)
    return raw, raw:le_float()
end

function KaitaiStream:read_f8le()
    local raw = self:read(8)
    return raw, raw:le_float()
end

--=============================================================================
-- Unaligned bit values
--=============================================================================

function KaitaiStream:align_to_byte()
    self.bits = 0
    self.bits_left = 0
end

-- TODO: look at tvbrange:bitfield()

function KaitaiStream:read_bits_int_be(n)
    assert(false, "Reading bits is not implemented")
    -- local bits_needed = n - self.bits_left
    -- if bits_needed > 0 then
    --     -- 1 bit  => 1 byte
    --     -- 8 bits => 1 byte
    --     -- 9 bits => 2 bytes
    --     local bytes_needed = math.ceil(bits_needed / 8)
    --     local buf = self._io:read(bytes_needed)
    --     for i = 1, #buf do
    --         local byte = buf:byte(i)
    --         self.bits = self.bits << 8
    --         self.bits = self.bits | byte
    --         self.bits_left = self.bits_left + 8
    --     end
    -- end

    -- -- Raw mask with required number of 1s, starting from lowest bit
    -- local mask = (1 << n) - 1
    -- -- Shift self.bits to align the highest bits with the mask & derive reading result
    -- local shift_bits = self.bits_left - n
    -- local res = (self.bits >> shift_bits) & mask
    -- -- Clear top bits that we've just read => AND with 1s
    -- self.bits_left = self.bits_left - n
    -- mask = (1 << self.bits_left) - 1
    -- self.bits = self.bits & mask

    -- return res
end

function KaitaiStream:read_bits_int_le(n)
    assert(false, "Reading bits is not implemented")
    -- local bits_needed = n - self.bits_left
    -- if bits_needed > 0 then
    --     -- 1 bit  => 1 byte
    --     -- 8 bits => 1 byte
    --     -- 9 bits => 2 bytes
    --     local bytes_needed = math.ceil(bits_needed / 8)
    --     local buf = self._io:read(bytes_needed)
    --     for i = 1, #buf do
    --         local byte = buf:byte(i)
    --         self.bits = self.bits | (byte << self.bits_left)
    --         self.bits_left = self.bits_left + 8
    --     end
    -- end

    -- -- Raw mask with required number of 1s, starting from lowest bit
    -- local mask = (1 << n) - 1
    -- -- Derive reading result
    -- local res = self.bits & mask
    -- -- Remove bottom bits that we've just read by shifting
    -- self.bits = self.bits >> n
    -- self.bits_left = self.bits_left - n

    -- return res
end

--=============================================================================
-- Byte arrays
--=============================================================================

function KaitaiStream:read_bytes(n)
    local r = self:read(n)
    if r == nil then
        r = self:read(0)
    end

    if r:len() < n then
        error("requested " .. n .. " bytes, but got only " .. r:len() .. " bytes")
    end

    return r, r:string()
end

function KaitaiStream:read_bytes_full()
    local r = self:read("*all")
    if r == nil then
        r = self:read(0)
    end

    return r, r:string()
end

function KaitaiStream:read_bytes_term(term, include_term, consume_term, eos_error)
    local start_pos = self:pos()
    local r_len = 0
    local result_bytes = {}

    while true do
        local c = self:read(1)
        r_len = r_len + 1

        if c == nil then
            if eos_error then
                error("end of stream reached, but no terminator " .. term .. " found")
            else
                self:seek(start_pos)
                local raw = self:read(r_len)
                return raw, raw:string()
            end
        end
        
        local c_val = c:int()
        if c_val == term then
            if include_term then
                table.insert(result_bytes, c_val)
            end
            if not consume_term then
                r_len = r_len - 1
            end
            self:seek(start_pos)

            local raw = self:read(r_len)
            return raw, string.char(table.unpack(result_bytes))
        else
            table.insert(result_bytes, c_val)
        end
    end
end

function KaitaiStream:ensure_fixed_contents(expected)
    local raw, actual = self:read_bytes(#expected)

    if actual ~= expected then
        error("unexpected fixed contents: got " ..  actual .. ", was waiting for " .. expected)
    end

    return raw, actual
end

function KaitaiStream.bytes_strip_right(pad_byte, raw, src)
    -- assert(false, "bytes_strip_right is not implemented (arguments " .. src .. ", " .. pad_byte .. ")")
    local new_len = src:len()

    while new_len >= 1 and src:byte(new_len) == pad_byte do
        new_len = new_len - 1
    end

    return raw, src:sub(1, new_len)
end

function KaitaiStream.bytes_terminate(term, include_term, raw, src)
    -- assert(false, "bytes_terminate is not implemented (arguments " .. src .. ", " .. term .. ")")
    local new_len = 1
    local max_len = src:len()

    while new_len <= max_len and src:byte(new_len) ~= term do
        new_len = new_len + 1
    end

    if include_term and new_len <= max_len then
        new_len = new_len + 1
    end

    return raw, src:sub(1, new_len - 1)
end

--=============================================================================
-- Byte array processing
--=============================================================================

function KaitaiStream.process_xor_one(data, key)
    assert(false, "process_xor_one is not implemented")
    -- local r = ""

    -- for i = 1, #data do
    --     local c = data:byte(i) ~ key
    --     r = r .. string.char(c)
    -- end

    -- return r
end

function KaitaiStream.process_xor_many(data, key)
    assert(false, "process_xor_many is not implemented")
    -- local r = ""
    -- local kl = key:len()
    -- local ki = 1

    -- for i = 1, #data do
    --     local c = data:byte(i) ~ key:byte(ki)
    --     r = r .. string.char(c)
    --     ki = ki + 1
    --     if ki > kl then
    --         ki = 1
    --     end
    -- end

    -- return r
end

function KaitaiStream.process_rotate_left(data, amount, group_size)
    assert(false, "process_rotate_left is not implemented")
    -- if group_size ~= 1 then
    --     error("unable to rotate group of " .. group_size .. " bytes yet")
    -- end

    -- local result = ""
    -- local mask = group_size * 8 - 1
    -- local anti_amount = -amount & mask

    -- for i = 1, #data  do
    --     local c = data:byte(i)
    --     c = ((c << amount) & 0xFF) | (c >> anti_amount)
    --     result = result .. string.char(c)
    -- end

    -- return result
end
