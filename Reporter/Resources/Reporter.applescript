on run argv
	-- load the arguments
	set reportFilePath to (item 1 of argv)
	set uid to (item 2 of argv)
	set imageFilePath to (item 3 of argv)
	set caption to (item 4 of argv)
	(*
     set replaceFlag to (item 5 of argv)
     *)
	
	-- get the image size
	tell application "Image Events"
		set im to open imageFilePath
		copy dimensions of im to {iwidth, iheight}
		copy resolution of im to {iresx, iresy}
		set iwidth to iwidth / iresx * 2.54 -- 1 inch = 2.54 cm
		set iheight to iheight / iresy * 2.54 --
		close im
	end tell
	
	-- put the image in the Pages document
	tell application "Pages"
		-- open the document
		open reportFilePath
		
		-- insert the image as a text box in a paragraph with style Caption
		tell front document
			-- make sure the Caption style exists -- yes, in english...
			try
				set sc to paragraph style "Caption"
				-- the Caption style often has 0 spacing when unused… fix this, or our insertions will be confusing
				if space before of sc is 0 and space after of sc is 0 then
					set space before of sc to 5
					set space after of sc to 5
				end if
                on error errmsg number errnbr
				make new paragraph style with properties {name:"Caption", alignment:center, space before:5, space after:5, keep lines together:true, keep with next paragraph:false, font name:"Helvetica", font size:11, italic:true}
			end try
			
			(*
             -- is there already a text box with the current uid for name?
             set tb to 0
             if replaceFlag is equal to 1 then
             repeat with itb in text boxes
             if name of itb as Unicode text is equal to uid as Unicode text then
             set tb to itb
             exit repeat
             end if
             end repeat
             end if
             
             if tb is not equal to 0 then
             set image data of tb to imageFilePath
             else
             *)
			
			-- append a new paragraph that will represent image's caption
			set p to make new paragraph at after last paragraph
			set text of p to (text of p & caption as Unicode text) -- TODO: it would be great to insert a shift-newline: (text of p & shift-newline & caption as Unicode text) - returns are captured as "next paragraph", we just want a newline
			-- insert a text box to include the image. this is the only way Pages.app officially allows us to insert images
			make new text box at after p with properties {fill type:plain image, image data:imageFilePath, stroke type:none, extra space:1, placement:moving, name:uid, width:iwidth, height:iheight}
			-- apply some styling to the newly created text box (the image) and paragraph
			set paragraph style of last paragraph to paragraph style "Caption"
			set width of last text box to "100%"
			
			set nwidth to width of last text box
			-- if the image width won't fit, adapt the height
			if nwidth < iwidth then
				set height of last text box to iheight / iwidth * nwidth
			end if
			-- if the image is much smaller than the page width, force the caption text to be centered
			--if nwidth - iwidth > nwidth / 3 then
			set alignment of last paragraph to center -- TODO: do we want to modify the Caption style instead?
			--end if

            -- because of a bug in Pages, we need to re-enter the text box height, or the text box size won't be properly saved
            set nheight to height of last text box
            set height of last text box to 1
            set height of last text box to nheight
            
			(*
             end if
             *)
		end tell
	end tell
end run