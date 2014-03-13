SuperStrict
Import brl.Map
'Import brl.OpenALAudio
'Import brl.FreeAudioAudio
Import brl.WAVLoader
Import brl.OGGLoader
Import "basefunctions.bmx"


Import maxmod2.ogg
Import maxmod2.rtaudio
Import MaxMod2.WAV

?Linux
'linux needs a different maxmod-implementation

'maybe move it to maxmod - or leave it out to save dependencies if not used
TMaxModRtAudioDriver.Init("LINUX_PULSE")
?
'init has to be done for all
If Not SetAudioDriver("MaxMod RtAudio") Then Throw "Audio Failed"


'type to store music files (ogg) in it
'data is stored in bank
'Play-Method is adopted from maxmod2.bmx-Function "play"
Type TMusicStream
	Field bank:TBank
	Field loop:Int
	Field url:string


	Function Create:TMusicStream(url:Object, loop:Int=False)
		Local obj:TMusicStream = New TMusicStream
		obj.bank = LoadBank(url)
		obj.loop = loop
		obj.url = "unknown"
		if string(url) then obj.url=string(url)
		Return obj
	End Function


	Method isValid:int()
		if not self.bank then return FALSE
		return TRUE
	End Method


	Method GetChannel:TChannel(volume:Float)
		Local channel:TChannel = CueMusic(Self.bank, loop)
		channel.SetVolume(volume)
		Return channel
	End Method
End Type


Type TSoundManager
	Field soundFiles:TMap = CreateMap()
	Field musicChannel1:TChannel = Null
	Field musicChannel2:TChannel = Null
	Field activeMusicChannel:TChannel = Null
	Field inactiveMusicChannel:TChannel = Null

	Field sfxChannel_Elevator:TChannel = Null
	Field sfxChannel_Elevator2:TChannel = Null
	Field sfxVolume:Float = 1
	Field defaulTSfxDynamicSettings:TSfxSettings = Null

	Field sfxOn:Int = 1
	Field musicOn:Int = 1
	Field musicVolume:Float = 1
	Field nextMusicTitleVolume:Float = 1
	Field lastTitleNumber:Int = 0
	Field currentMusicStream:TMusicStream = Null
	Field nextMusicTitleStream:TMusicStream = Null

	Field currentMusic:TSound = Null
	Field nextMusicTitle:TSound = Null
	Field forceNextMusicTitle:Int = 0
	Field fadeProcess:Int = 0 '0 = nicht aktiv  1 = aktiv
	Field fadeOutVolume:Int = 1000
	Field fadeInVolume:Int = 0

	Field soundSources:TList = CreateList()
	Field receiver:TElementPosition

	Field _currentPlaylistName:string = "default"
	Field playlists:TMap = CreateMap()		'a named array of playlists, playlists contain available musicStreams

	global instance:TSoundManager
	global PREFIX_MUSIC:string = "MUSIC_"
	global PREFIX_SFX:string = "SFX_"


	Function Create:TSoundManager()
		Local manager:TSoundManager = New TSoundManager
		manager.musicChannel1 = AllocChannel()
		manager.musicChannel2 = AllocChannel()
		manager.sfxChannel_Elevator = AllocChannel()
		manager.sfxChannel_Elevator2 = AllocChannel()
		manager.defaulTSfxDynamicSettings = TSfxSettings.Create()
		Return manager
	End Function


	Function GetInstance:TSoundManager()
		if not instance then instance = TSoundManager.Create()
		return instance
	End Function


	Method GetDefaultReceiver:TElementPosition()
		Return receiver
	End Method


	Method SetDefaultReceiver(_receiver:TElementPosition)
		receiver = _receiver
	End Method


	'playlists is a comma separated string of playlists this music wants to
	'be stored in
	Method AddSound:int(name:string, sound:object, playlists:string="default")
		Self.soundFiles.insert(lower(name), sound)

		local playlistsArray:string[] = playlists.split(",")
		for local playlist:string = eachin playlistsArray
			playlist = playlist.trim() 'remove whitespace
			AddSoundToPlaylist(playlist, name, sound)
		Next
	End Method


	Method AddSoundToPlaylist(playlist:string="default", name:string, sound:object)
		if TSound(sound)
			playlist = PREFIX_SFX + lower(playlist)
		elseif TMusicStream(sound)
			playlist = PREFIX_MUSIC + lower(playlist)
		endif
		name = lower(name)

		'if not done yet - create a new playlist entry
		'fetch the playlist
		local playlistContainer:TList
		if not playlists.contains(playlist)
			playlistContainer = CreateList()
			playlists.insert(playlist, playlistContainer)
		else
			playlistContainer = TList(playlists.ValueForKey(playlist))
		endif
		playlistContainer.AddLast(sound)
	End Method


	Method GetCurrentPlaylist:string()
		return _currentPlaylistName:string
	End Method


	Method SetCurrentPlaylist(name:string="default")
		_currentPlaylistName = name
	End Method


	'use this method if multiple sfx for a certain event are possible
	'(so eg. multiple "door open/close"-sounds to make variations
	Method GetRandomSfxFromPlaylist:TSound(playlist:string)
		local playlistContainer:TList = TList(playlists.ValueForKey(PREFIX_SFX + playlist))
		if not playlistContainer then print "playlist: "+playlist+" not found."; return null
		if playlistContainer.count() = 0 then print "empty list:"+PREFIX_SFX + playlist; return NULL
		return TSound(playlistContainer.ValueAtIndex(Rand(0, playlistContainer.count()-1)))
	End Method


	'if avoidMusic is set, the function tries to return another music (if possible)
	Method GetRandomMusicFromPlaylist:TMusicStream(playlist:string, avoidMusic:TMusicStream=null)
		local playlistContainer:TList = TList(playlists.ValueForKey(PREFIX_MUSIC + playlist))
		if not playlistContainer
			'TDevHelper.Log("GetRandomMusicFromPlaylist", "No playlist: "+playlist+" found.", LOG_WARNING)
			return Null
		endif
		if playlistContainer.count() = 0
			'TDevHelper.Log("GetRandomMusicFromPlaylist", "playlist: "+playlist+" is empty.", LOG_WARNING)
			return Null
		endif

		local result:TMusicStream
		'try to find another music file
		if avoidMusic and playlistContainer.count()>1
			repeat
				result = TMusicStream(playlistContainer.ValueAtIndex(Rand(0, playlistContainer .count()-1)))
			until result <> avoidMusic
		else
			result = TMusicStream(playlistContainer.ValueAtIndex(Rand(0, playlistContainer .count()-1)))
		endif
		return result

'		local playlistContainer:TMusicStream[] = TMusicStream[](playlists.ValueForKey("MUSIC_"+playlist))
'		if playlistContainer.length = 0 then print "empty list:"+"MUSIC_"+playlist; return NULL
'		return playlistContainer[Rand(0, playlistContainer.length-1)]
	End Method


	Method RegisterSoundSource(soundSource:TSoundSourceElement)
		If Not soundSources.Contains(soundSource) Then soundSources.AddLast(soundSource)
	End Method


	Method IsPlaying:int()
		If not activeMusicChannel then return FALSE
		return activeMusicChannel.Playing()
	End Method


	Method Mute:int(bool:int=TRUE)
		if bool
			TDevHelper.log("TSoundManager.Mute()", "Muting all sounds", LOG_DEBUG)
		else
			TDevHelper.log("TSoundManager.Mute()", "Unmuting all sounds", LOG_DEBUG)
		endif
		MuteSfx(bool)
		MuteMusic(bool)
	End Method


	Method MuteSfx:int(bool:int=TRUE)
		if bool
			TDevHelper.log("TSoundManager.MuteSfx()", "Muting all sound effects", LOG_DEBUG)
		else
			TDevHelper.log("TSoundManager.MuteSfx()", "Unmuting all sound effects", LOG_DEBUG)
		endif
		For Local element:TSoundSourceElement = EachIn soundSources
			element.mute(bool)
		Next

		sfxOn = not bool
	End Method


	Method MuteMusic:int(bool:int=TRUE)
		if bool
			TDevHelper.log("TSoundManager.MuteMusic()", "Muting music", LOG_DEBUG)
		else
			TDevHelper.log("TSoundManager.MuteMusic()", "Unmuting music", LOG_DEBUG)
		endif

		if bool
			if activeMusicChannel then PauseChannel(activeMusicChannel)
			if inactiveMusicChannel then inactiveMusicChannel.Stop()
		else
			if activeMusicChannel then ResumeChannel(activeMusicChannel)
		endif
		musicOn = not bool
	End Method


	Method IsMuted:int()
		if sfxOn or musicOn then return FALSE
		return TRUE
	End Method


	Method HasMutedMusic:int()
		return not musicOn
	End Method


	Method HasMutedSfx:int()
		return not sfxOn
	End Method


	Method Update:int()
		'skip updates if muted
		if isMuted() then return TRUE

		if sfxOn
			For Local element:TSoundSourceElement = EachIn soundSources
				element.Update()
			Next
		endif

		If not HasMutedMusic()
			'Wenn der Musik-Channel nicht l�uft, dann muss nichts gemacht werden
			If not activeMusicChannel then return TRUE

			'if the music didn't stop yet
			If activeMusicChannel.Playing()
				If (forceNextMusicTitle And nextMusicTitleStream) Or fadeProcess > 0
'					TDevHelper.log("TSoundManager.Update()", "FadeOverToNextTitle", LOG_DEBUG)
					FadeOverToNextTitle()
				EndIf
			'no music is playing, just start
			Else
				TDevHelper.log("TSoundManager.Update()", "PlayMusicPlaylist", LOG_DEBUG)
				PlayMusicPlaylist(GetCurrentPlaylist())
			EndIf
		EndIf
	End Method


	Method FadeOverToNextTitle()
		If (fadeProcess = 0) Then
			fadeProcess = 1
			inactiveMusicChannel = nextMusicTitleStream.GetChannel(0)
			ResumeChannel(inactiveMusicChannel)
			nextMusicTitleStream = Null

			forceNextMusicTitle = False
			fadeOutVolume = 1000
			fadeInVolume = 0
		EndIf

		If (fadeProcess = 1) Then 'Das fade out des aktiven Channels
			fadeOutVolume = fadeOutVolume - 15
			activeMusicChannel.SetVolume(fadeOutVolume/1000.0 * musicVolume)

			fadeInVolume = fadeInVolume + 15
			inactiveMusicChannel.SetVolume(fadeInVolume/1000.0 * nextMusicTitleVolume)
		EndIf

		If fadeOutVolume <= 0 And fadeInVolume >= 1000 Then
			fadeProcess = 0 'Prozess beendet
			musicVolume = nextMusicTitleVolume
			SwitchMusicChannels()
		EndIf
	End Method


	Method SwitchMusicChannels()
		Local channelTemp:TChannel = Self.activeMusicChannel
		Self.activeMusicChannel = Self.inactiveMusicChannel
		Self.inactiveMusicChannel = channelTemp
		Self.inactiveMusicChannel.Stop()
	End Method


	Method PlaySfx(sfx:TSound, channel:TChannel)
		if not HasMutedSfx() and sfx then PlaySound(sfx, Channel)
	End Method


	Method PlayMusicPlaylist(playlist:string)
		PlayMusicOrPlayList(playlist, true)
	End Method


	Method PlayMusic(music:string)
		PlayMusicOrPlayList(music, FALSE)
	End Method


	Method PlayMusicOrPlaylist:int(name:String, fromPlaylist:int=FALSE)
		if HasMutedMusic() then return TRUE

		if fromPlaylist
			nextMusicTitleStream = GetMusicStream("", name)
			nextMusicTitleVolume = GetMusicVolume(name)
			if nextMusicTitleStream
				SetCurrentPlaylist(name)
				TDevHelper.Log("PlayMusicOrPlaylist", "GetMusicStream from Playlist ~q"+name+"~q. Also set current playlist to it.", LOG_DEBUG)
			else
				TDevHelper.Log("PlayMusicOrPlaylist", "GetMusicStream from Playlist ~q"+name+"~q not possible. No Playlist.", LOG_DEBUG)
			endif
		else
			nextMusicTitleStream = GetMusicStream(name, "")
			nextMusicTitleVolume = GetMusicVolume(name)
			TDevHelper.Log("PlayMusicOrPlaylist", "GetMusicStream by name ~q"+name+"~q", LOG_DEBUG)
		endif

		forceNextMusicTitle = True

		'Wenn der Musik-Channel noch nicht laeuft, dann jetzt starten
		If not activeMusicChannel Or Not activeMusicChannel.Playing()
			if not nextMusicTitleStream
				TDevHelper.Log("PlayMusicOrPlaylist", "could not start activeMusicChannel: no next music found", LOG_DEBUG)
			else
				TDevHelper.Log("PlayMusicOrPlaylist", "start activeMusicChannel", LOG_DEBUG)
				Local musicVolume:Float = nextMusicTitleVolume
				activeMusicChannel = nextMusicTitleStream.GetChannel(musicVolume)
				ResumeChannel(activeMusicChannel)

				forceNextMusicTitle = False
			endif
		EndIf
	End Method


	'returns if there would be a stream to play
	'use this to avoid music changes if there is no new stream available
	Method HasMusicStream:int(music:String="", playlist:string="")
		if playlist=""
			return null <> TMusicStream(soundFiles.ValueForKey(lower(music)))
		else
			return null <> GetRandomMusicFromPlaylist(playlist, nextMusicTitleStream)
		endif
	End Method


	Method GetMusicStream:TMusicStream(music:String="", playlist:string="")
		Local result:TMusicStream

		if playlist=""
			result = TMusicStream(soundFiles.ValueForKey(lower(music)))
			TDevHelper.log("TSoundManager.GetMusicStream()", "Play music: " + music, LOG_DEBUG)
		else
			result = GetRandomMusicFromPlaylist(playlist, nextMusicTitleStream)
			rem
			if result
				TDevHelper.log("TSoundManager.GetMusicStream()", "Play random music from playlist: ~q" + playlist +"~q  file: ~q"+result.url+"~q", LOG_DEBUG)
			else
				TDevHelper.log("TSoundManager.GetMusicStream()", "Cannot play random music from playlist: ~q" + playlist +"~q, nothing found.", LOG_DEBUG)
			endif
			endrem
		endif

		Return result
	End Method


	Method GetSfx:TSound(sfx:String="", playlist:string="")
		Local result:TSound
		if playlist=""
			result = TSound(soundFiles.ValueForKey(lower(sfx)))
			'TDevHelper.log("TSoundManager.GetSfx()", "Play sfx: " + sfx, LOG_DEBUG)
		else
			result = GetRandomSfxFromPlaylist(playlist)
			'TDevHelper.log("TSoundManager.GetSfx()", "Play random sfx from playlist: " + playlist, LOG_DEBUG)
		endif

		Return result
	End Method


	'by default all sfx share the same volume
	Method GetSfxVolume:Float(sfx:String)
		Return 0.2
	End Method

	'by default all music share the same volume
	Method GetMusicVolume:float(music:String)
		Return 1.0
	End Method
End Type




'Diese Basisklasse ist ein Wrapper f�r einen normalen Channel mit erweiterten Funktionen
Type TSfxChannel
	Field Channel:TChannel = AllocChannel()
	Field CurrentSfx:String
	Field CurrentSettings:TSfxSettings
	Field MuteAfterCurrentSfx:Int


	Function Create:TSfxChannel()
		Return New TSfxChannel
	End Function


	Method PlaySfx(sfx:String, settings:TSfxSettings=Null)
		CurrentSfx = sfx
		CurrentSettings = settings

		AdjustSettings(False)

		Local sound:TSound = TSoundManager.GetInstance().GetSfx(sfx)
		TSoundManager.GetInstance().PlaySfx(sound, Channel)
	End Method


	Method PlayRandomSfx(playlist:String, settings:TSfxSettings=Null)
		CurrentSfx = playlist
		CurrentSettings = settings

		AdjustSettings(False)

		Local sound:TSound = TSoundManager.GetInstance().GetSfx("", playlist)
		TSoundManager.GetInstance().PlaySfx(sound, Channel)
		'if sound then PlaySound(sound, channel)
	End Method


	Method IsActive:Int()
		Return Channel.Playing()
	End Method


	Method Stop()
		Channel.Stop()
	End Method


	Method Mute(bool:int=TRUE)
		if bool
			If MuteAfterCurrentSfx And IsActive()
				AdjustSettings(True)
			Else
				Channel.SetVolume(0)
			EndIf
		else
			Channel.SetVolume(TSoundManager.GetInstance().sfxVolume)
		endif
	End Method


	Method AdjustSettings(isUpdate:Int)
		If Not isUpdate
			channel.SetVolume(TSoundManager.GetInstance().sfxVolume * 0.75 * CurrentSettings.GetVolume()) '0.75 ist ein fixer Wert die Lautst�rke der Sfx reduzieren soll
		EndIf
	End Method
End Type




'Der dynamische SfxChannel hat die M�glichkeit abh�ngig von der Position von Sound-Quelle und Empf�nger dynamische Modifikationen an den Einstellungen vorzunehmen. Er wird bei jedem Update aktualisiert.
Type TDynamicSfxChannel Extends TSfxChannel
	Field Source:TSoundSourceElement
	Field Receiver:TElementPosition


	Function CreateDynamicSfxChannel:TSfxChannel(source:TSoundSourceElement=Null)
		Local sfxChannel:TDynamicSfxChannel = New TDynamicSfxChannel
		sfxChannel.Source = source
		Return sfxChannel
	End Function


	Method SetReceiver(_receiver:TElementPosition)
		Self.Receiver = _receiver
	End Method


	Method AdjustSettings(isUpdate:Int)
		Local sourcePoint:TPoint = Source.GetCenter()
		Local receiverPoint:TPoint = Receiver.GetCenter() 'Meistens die Position der Spielfigur

		If CurrentSettings.forceVolume
			channel.SetVolume(CurrentSettings.defaultVolume)
			'print "Volume:" + CurrentSettings.defaultVolume
		Else
			'Lautst�rke ist Abh�ngig von der Entfernung zur Ger�uschquelle
			Local distanceVolume:Float = CurrentSettings.GetVolumeByDistance(Source, Receiver)
			channel.SetVolume(TSoundManager.GetInstance().sfxVolume * distanceVolume) ''0.75 ist ein fixer Wert die Lautst�rke der Sfx reduzieren soll
			'print "Volume: " + (SoundManager.sfxVolume * distanceVolume)
		EndIf

		If (sourcePoint.z = 0) Then
			'170 Grenzwert = Erst aber dem Abstand von 170 (gef�hlt/gesch�tzt) h�rt man nur noch von einer Seite.
			'Ergebnis sollte ungef�hr zwischen -1 (links) und +1 (rechts) liegen.
			If CurrentSettings.forcePan
				channel.SetPan(CurrentSettings.defaultPan)
			Else
				channel.SetPan(Float(sourcePoint.x - receiverPoint.x) / 170)
			EndIf
			channel.SetDepth(0) 'Die Tiefe spielt keine Rolle, da elementPoint.z = 0
		Else
			Local zDistance:Float = TPoint.DistanceOfValues(sourcePoint.z, receiverPoint.z)

			If CurrentSettings.forcePan
				channel.SetPan(CurrentSettings.defaultPan)
				'print "Pan:" + CurrentSettings.defaultPan
			Else
				Local xDistance:Float = TPoint.DistanceOfValues(sourcePoint.x, receiverPoint.x)
				Local yDistance:Float = TPoint.DistanceOfValues(sourcePoint.y, receiverPoint.y)

				Local angleZX:Float = ATan(zDistance / xDistance) 'Winkelfunktion: Welchen Winkel hat der H�rer zur Soundquelle. 90� = davor/dahiner    0� = gleiche Ebene	tan(alpha) = Gegenkathete / Ankathete

				Local rawPan:Float = ((90 - angleZX) / 90)
				Local panCorrection:Float = Max(0, Min(1, xDistance / 170)) 'Den r/l Effekt sollte noch etwas abgeschw�cht werden, wenn die Quelle nah ist
				Local correctPan:Float = rawPan * panCorrection

				'0� => Aus einer Richtung  /  90� => aus beiden Richtungen
				If (sourcePoint.x < receiverPoint.x) Then 'von links
					channel.SetPan(-correctPan)
					'print "Pan:" + (-correctPan) + " - angleZX: " + angleZX + " (" + xDistance + "/" + zDistance + ")    # " + rawPan + " / " + panCorrection
				ElseIf (sourcePoint.x > receiverPoint.x) Then 'von rechts
					channel.SetPan(correctPan)
					'print "Pan:" + correctPan + " - angleZX: " + angleZX + " (" + xDistance + "/" + zDistance + ")    # " + rawPan + " / " + panCorrection
				Else
					channel.SetPan(0)
				EndIf
			EndIf

			If CurrentSettings.forceDepth
				channel.SetDepth(CurrentSettings.defaultDepth)
				'print "Depth:" + CurrentSettings.defaultDepth
			Else
				Local angleOfDepth:Float = ATan(receiverPoint.DistanceTo(sourcePoint, False) / zDistance) '0 = direkt hinter mir/vor mir, 90� = �ber/unter/neben mir

				If sourcePoint.z < 0 Then 'Hintergrund
					channel.SetDepth(-((90 - angleOfDepth) / 90)) 'Minuswert = Hintergrund / Pluswert = Vordergrund
					'print "Depth:" + (-((90 - angleOfDepth) / 90)) + " - angle: " + angleOfDepth + " (" + receiverPoint.DistanceTo(sourcePoint, false) + "/" + zDistance + ")"
				ElseIf sourcePoint.z > 0 Then 'Vordergrund
					channel.SetDepth((90 - angleOfDepth) / 90) 'Minuswert = Hintergrund / Pluswert = Vordergrund
					'print "Depth:" + ((90 - angleOfDepth) / 90) + " - angle: " + angleOfDepth + " (" + receiverPoint.DistanceTo(sourcePoint, false) + "/" + zDistance + ")"
				EndIf
			EndIf
		EndIf
	End Method
End Type




Type TSfxSettings
	Field forceVolume:Float = False
	Field forcePan:Float = False
	Field forceDepth:Float = False

	Field defaultVolume:Float = 1
	Field defaultPan:Float = 0
	Field defaultDepth:Float = 0

	Field nearbyDistanceRange:Int = -1
'	Field nearbyDistanceRangeTopY:int -1
'	Field nearbyDistanceRangeBottomY:int -1   hier war ich
	Field maxDistanceRange:Int = 1000

	Field nearbyRangeVolume:Float = 1
	Field midRangeVolume:Float = 0.8
	Field minVolume:Float = 0


	Function Create:TSfxSettings()
		Return New TSfxSettings
	End Function


	Method GetVolume:Float()
		Return defaultVolume
	End Method


	Method GetVolumeByDistance:Float(source:TSoundSourceElement, receiver:TElementPosition)
		Local currentDistance:Int = source.GetCenter().DistanceTo(receiver.getCenter())

		Local result:Float = midRangeVolume
		If (currentDistance <> -1) Then
			If currentDistance > Self.maxDistanceRange Then 'zu weit weg
				result = Self.minVolume
			ElseIf currentDistance < Self.nearbyDistanceRange Then 'sehr nah dran
				result = Self.nearbyRangeVolume
			Else 'irgendwo dazwischen
				result = midRangeVolume * (Float(Self.maxDistanceRange) - Float(currentDistance)) / Float(Self.maxDistanceRange)
			EndIf
		EndIf

		Return result
	End Method
End Type




'Das ElementPositionzeug kann auch eventuell wo anders hin
Type TElementPosition 'Basisklasse f�r verschiedene Wrapper
	Method GetID:String() Abstract
	Method GetCenter:TPoint() Abstract
	Method IsMovable:Int() Abstract
End Type




Type TSoundSourceElement Extends TElementPosition
	Field SfxChannels:TMap = CreateMap()


	Method GetIsHearable:Int() Abstract
	Method GetChannelForSfx:TSfxChannel(sfx:String) Abstract
	Method GetSfxSettings:TSfxSettings(sfx:String) Abstract
	Method OnPlaySfx:Int(sfx:String) Abstract


	Method GetReceiver:TElementPosition()
		Return TSoundManager.GetInstance().GetDefaultReceiver()
	End Method


	Method PlayRandomSfx(playlist:string, sfxSettings:TSfxSettings=Null)
		PlaySfxOrPlaylist(playlist, sfxSettings, TRUE)
	End Method


	Method PlaySfx(sfx:string, sfxSettings:TSfxSettings=Null)
		PlaySfxOrPlaylist(sfx, sfxSettings, FALSE)
	End Method


	Method PlaySfxOrPlaylist(name:String, sfxSettings:TSfxSettings=Null, playlistMode:int=FALSE)
		If Not GetIsHearable() Then Return
		If Not OnPlaySfx(name) Then Return
		'print GetID() + " # PlaySfx: " + sfx

		TSoundManager.GetInstance().RegisterSoundSource(Self)

		Local channel:TSfxChannel = GetChannelForSfx(name)
		Local settings:TSfxSettings = sfxSettings
		If settings = Null Then settings = GetSfxSettings(name)

		If TDynamicSfxChannel(channel)
			TDynamicSfxChannel(channel).SetReceiver(GetReceiver())
		EndIf

		if playlistMode
			channel.PlayRandomSfx(name, settings)
		else
			channel.PlaySfx(name, settings)
		endif
		'print GetID() + " # End PlaySfx: " + sfx
	End Method


	Method PlayOrContinueRandomSfx(playlist:string, sfxSettings:TSfxSettings=Null)
		PlayOrContinueSfxOrPlaylist(playlist, sfxSettings, TRUE)
	End Method


	Method PlayOrContinueSfx(sfx:string, sfxSettings:TSfxSettings=Null)
		PlayOrContinueSfxOrPlaylist(sfx, sfxSettings, FALSE)
	End Method


	Method PlayOrContinueSfxOrPlaylist(name:String, sfxSettings:TSfxSettings=Null, playlistMode:int=FALSE)
		Local channel:TSfxChannel = GetChannelForSfx(name)
		If Not channel.IsActive()
			'Print "PlayOrContinueSfx: start"
			PlaySfxOrPlaylist(name, sfxSettings, playlistMode)
		Else
			'Print "PlayOrContinueSfx: Continue"
		EndIf
	End Method


	Method Stop(sfx:String)
		Local channel:TSfxChannel = GetChannelForSfx(sfx)
		channel.Stop()
	End Method


	Method Mute:int(bool:int=TRUE)
		For Local sfxChannel:TSfxChannel = EachIn MapValues(SfxChannels)
			sfxChannel.Mute(bool)
		Next
	End Method


	Method Update()
		If GetIsHearable()
			For Local sfxChannel:TSfxChannel = EachIn MapValues(SfxChannels)
				If sfxChannel.IsActive() Then sfxChannel.AdjustSettings(True)
			Next
		Else
			For Local sfxChannel:TSfxChannel = EachIn MapValues(SfxChannels)
				sfxChannel.Mute()
			Next
		EndIf
	End Method


	Method AddDynamicSfxChannel:TSfxChannel(name:String, muteAfterSfx:Int=False)
		Local sfxChannel:TSfxChannel = TDynamicSfxChannel.CreateDynamicSfxChannel(Self)
		sfxChannel.MuteAfterCurrentSfx = muteAfterSfx
		SfxChannels.insert(name, sfxChannel)
		return sfxChannel
	End Method


	Method GetSfxChannelByName:TSfxChannel(name:String)
		Return TSfxChannel(MapValueForKey(SfxChannels, name))
	End Method
End Type