script ASOCscript
	property parent : class "NSObject"
	
	on sayHello()
		say "\"Hello\""
	end sayHello
	
	on getFinderVersion()
		return version of application "Finder"
	end getFinderVersion
	
	on say_(phrase)
		say "\"" & phrase & "\""
	end say_
	
end script
