--- @sync entry
return {
	entry = function(_, job)
		local h = cx.active.current.hovered
		if not h then
			return
		end
		-- The `y` shell wrapper leaves YAZI_PICKER unset (browse/edit mode); the
		-- Alt+y command-line picker sets YAZI_PICKER=1 (pick-a-path mode) and
		-- exports YAZI_CHOOSER_FILE so we can hand back a directory path.
		local picker = os.getenv("YAZI_PICKER") == "1"
		if h.cha.is_dir then
			if job.args[1] == "cd" then
				if picker then
					-- Alt+y, <Right> on a dir: pick it. `open` only writes files
					-- to the chooser file, so write the dir path ourselves. Must
					-- be a synchronous io.write here — a `shell` emit would lose
					-- the race against `quit` and never run.
					local out = os.getenv("YAZI_CHOOSER_FILE")
					if out then
						local f = io.open(out, "w")
						if f then
							f:write(tostring(h.url))
							f:close()
						end
					end
					ya.emit("quit", {})
				else
					-- browse, <Right> on a dir: enter it, then quit so the shell
					-- wrapper's --cwd-file lands the terminal inside it.
					ya.emit("enter", {})
					ya.emit("quit", {})
				end
			else
				-- <Enter> on a dir: just go in.
				ya.emit("enter", {})
			end
		elseif picker then
			-- file, Alt+y picker: write the path to --chooser-file and quit so
			-- it gets inserted into the command line.
			ya.emit("open", { hovered = true })
		else
			-- file, normal browse: edit in nano, blocking, return to yazi.
			ya.emit("shell", { 'nano "$@"', block = true })
		end
	end,
}
