local NoteBase = {}

function NoteBase:NoteBase()
	local self = {}

	function self:update(dt_scale) error("NoteBase must implement update") end
	function self:should_remove() error("NoteBase must implement should_remove") return false end
	function self:do_remove() error("NoteBase must implement do_remove") end

	function self:test_hit() error("NoteBase must implement test_hit") return false,0 end
	function self:on_hit(note_result, i_notes) error("NoteBase must implement on_hit") end

	function self:test_release() error("NoteBase must implement test_release") return false,0 end
	function self:on_release(note_result,i_notes) error("NoteBase must implement on_release") end

	function self:get_track_index() error("NoteBase must implement get_track_index") return 0 end

	return self
end

return NoteBase
