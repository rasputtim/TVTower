
Type TPlayerProgrammePlan
	Field Programmes:TObjectList	= TObjectList.Create(1000)
	Field Contracts:TObjectList		= TObjectList.Create(1000)
	Field News:TObjectList			= TObjectList.Create(1000)
	Global List:TObjectList			= TObjectList.Create(1000)

	Field parent:TPlayer

	Method ClearLists()
		List.Clear()
		Programmes.Clear()
		Contracts.Clear()
		News.Clear()
	End Method

	Function Create:TPlayerProgrammePlan(parent:TPlayer)
		Local obj:TPlayerProgrammePlan = New TPlayerProgrammePlan
		TPlayerProgrammePlan.List.AddLast(obj)
		obj.parent = parent
		Return obj
	End Function

	Method ProgrammePlaceable:Int(Programme:TProgramme, time:Int = -1, day:Int = -1)
		If Programme = Null Then Return 0
		If time = -1 Then time = Game.GetActualHour()
		If day  = -1 Then day  = Game.day

		If GetActualProgramme(time, day) = Null
			If time + Programme.blocks - 1 > 23 Then time:-24;day:+1 'sendung geht bis nach 0 Uhr
			If GetActualProgramme(time + Programme.blocks - 1, day) = Null then Return 1
		EndIf
		Return 0
	End Method

	Method ContractPlaceable:Int(Contract:TContract, time:Int = -1, day:Int = -1)
		If Contract = Null Then Return 0
		If time = -1 Then time = Game.GetActualHour()
		If day  = -1 Then day  = Game.day
		If GetActualContract(time, day) = Null then Return 1
		Return 0
	End Method

	Method GetActualProgramme:TProgramme(time:Int = -1, day:Int = - 1)
		If time = -1 Then time = Game.GetActualHour()
		If day  = -1 Then day  = Game.day

		Local Programme:TProgramme=Null
		For Local i:Int = 0 To self.Programmes.Count()-1
			Programme = TProgramme(self.Programmes.Items[i] )
			If (Programme.sendtime + Programme.blocks - 1 >= time And Programme.sendtime <= time) And Programme.senddate = day Then Return Programme
		Next
		Return Null
	End Method

	Method GetActualContract:TContract(time:Int = -1, day:Int = - 1)
		If time = -1 Then time = Game.GetActualHour()
		If day  = -1 Then day  = Game.day

		Local contract:TContract=Null
		For Local i:Int = 0 To self.Contracts.Count()-1
			contract = TContract(self.Contracts.items[i] )
			If (contract.sendtime>= time And contract.sendtime <=time) And contract.senddate = day Then Return contract
		Next
		Return Null
	End Method

	Method GetActualAdBlock:TAdBlock(playerID:Int, time:Int = -1, day:Int = - 1)
		If time = -1 Then time = Game.GetActualHour()
		If day  = -1 Then day  = Game.day

		For Local adblock:TAdBlock= EachIn TAdBlock.List
			If adblock.owner = playerID
				If (adblock.contract.sendtime>= time And adblock.contract.sendtime <=time) And..
					adblock.contract.senddate = day Then Return adblock
			EndIf
		Next
		Return Null
	End Method

	Method GetActualNews:TNews(position:Int)
		Local _news:TNews=Null
		For Local i:Int = 0 To self.News.Count()-1
			_news = TNews(self.News.Items[i] )
			If _news.sendposition = position Then Return _news
		Next
	End Method

	Method RefreshProgrammePlan(day:Int)
		Local Programme:TProgramme = Null
		For Local i:Int = 0 To self.Programmes.count()-1
			Programme = TProgramme(self.Programmes.items[i] )
			If Programme <> Null AND Programme.senddate = day Then self.Programmes.RemovebyIndex(i)
		Next
		For Local ProgrammeBlock:TProgrammeBlock = EachIn TProgrammeBlock.List
			If ProgrammeBlock.owner = self.parent.playerID And Programmeblock.Programme.senddate = day
				self.AddProgramme(ProgrammeBlock.Programme)
			EndIf
		Next
	End Method

	Method RefreshAdPlan(day:Int)
		Local contract:TContract = Null
		For Local i:Int = 0 To self.Contracts.count()-1
			contract = TContract( self.Contracts.items[i] )
			If contract.senddate = day Then self.RemoveContract(contract)
		Next
		For Local Adblock:TAdBlock= EachIn TAdBlock.List
			If adblock.contract.owner = self.parent.playerID
				Print "REFRESH AD:ADDED "+adblock.contract.title;
				self.AddContract(adblock.contract)
			EndIf
		Next
	End Method

	Method RefreshNewsPlan()
		Local _news:TNews = Null
		For Local i:Int = 0 To self.News.count()-1
			_news = TNews( self.News.items[i] )
			self.removeNews(_news)
		Next
		For Local NewsBlock:TNewsBlock= EachIn TNewsBlock.List
			If Newsblock.news.owner = self.parent.playerID
				Print "REFRESH NEWS:ADDED "+newsblock.news.title
				self.AddNews(newsblock.news, newsblock.news.sendposition)
			EndIf
		Next
	End Method

	Method AddProgramme(_Programme:TProgramme, takeGivenDay:Byte=0)
		Local Programme:TProgramme = New TProgramme
		Programme = _programme
		If Not TakeGivenDay Then Programme.senddate = Game.daytoplan
		self.Programmes.AddLast(Programme)
	End Method

	'clones a TProgramme - a normal prog = otherprog
	'just creates a reference to this object, but we want
	'a real copy (to be able to send repeatitions of movies
	Method CloneProgramme:TProgramme(_Programme:TProgramme)
		Local typ:TTypeId = TTypeId.ForObject(TProgramme(_Programme))
	 	Local clone:TProgramme = New TProgramme
		For Local t:TField = EachIn typ.EnumFields()
			t.Set(clone, t.Get(_Programme))
		Next
		TProgramme(clone).clone = 1
		self.Programmes.AddLast(clone)
		Return clone
	End Method

	Method RemoveProgramme(_Programme:TProgramme)
		Local Programme:TProgramme = Null
		For Local i:Int = 0 To self.Programmes.Count()-1
			Programme = TProgramme(Programmes.Items[i] )
			If Programme.pid = _Programme.pid And Programme.senddate = _Programme.senddate And Programme.sendtime = _Programme.sendtime
				Programme.clone = 0
				self.Programmes.RemoveByIndex(i)
			EndIf
		Next
	End Method

	Method RemoveAllProgrammeInstances(_Programme:TProgramme)
		Local Blockarray:Object[] = TProgrammeBlock.List.ToArray()

		For Local j:Int = 0 To blockarray.Length-1
			If TProgrammeBlock(blockarray[j]).Programme.title = _programme.title And..
			   TProgrammeBlock(blockarray[j]).Programme.senddate >= game.day And..
			   TProgrammeBlock(blockarray[j]).owner = self.parent.playerID
				blockarray[j] = Null
			EndIf
		Next
		TProgrammeBlock.List.Clear()
		TProgrammeBlock.List = TList.FromArray(blockarray)

		Local Programme:TProgramme = Null
		For Local i:Int = 0 To self.Programmes.Count()-1
			Programme = TProgramme(self.Programmes.Items[i] )
			If Programme <> Null AND Programme.title = _programme.title
				Programme.clone = 0
				self.Programmes.RemoveByIndex(i)
			EndIf
		Next
	End Method

	Method AddContract(_Contract:TContract)
		Local contract:TContract = New TContract
		contract			= CloneContract(_Contract)
		contract.owner		= self.parent.playerID
		contract.senddate	= Game.daytoplan
		self.Contracts.AddLast(contract)
		GetPreviousContractCount(contract)
	End Method

	Method AddNews(_News:TNews, owner:Int, sendposition:Int =0)
		Local newsObj:TNews = New TNews
		newsObj				= CloneNews(_News)
		newsObj.owner		= self.parent.playerID
		newsObj.sendposition= sendposition  '(10,20,30,40 = news is used For Newsshow)
		self.News.AddLast(newsObj)
	End Method

	Method RemoveNews(_news:TNews)
		Local newsObj:TNews = Null
		For Local i:Int = 0 To self.News.Count()-1
			newsObj = TNews(self.News.Items[i] )
			If newsObj <> Null AND newsObj.title = _news.title And newsObj.owner = self.parent.playerID
				newsObj.sendposition= 0
				self.News.RemoveByIndex(i)
			EndIf
		Next
	End Method

	Function CloneNews:TNews(_news:TNews)
		Local typ:TTypeId = TTypeId.ForObject(_news)
		Local clone:TNews = New TNews
		For Local t:TField = EachIn typ.EnumFields()
			t.Set(clone, t.Get(_news))
		Next
		clone.sendposition = 0
		clone.owner = 0
		Return clone
	End Function

	'clones a TProgramme - a normal prog = otherprog
	'just creates a reference to this object, but we want
	'a real copy (to be able to send repeatitions of movies
	Function CloneContract:TContract(_contract:TContract)
		If _contract <> Null
			Local typ:TTypeId = TTypeId.ForObject(_contract)
			Local clone:TContract = New TContract
			For Local t:TField = EachIn typ.EnumFields()
				t.Set(clone, t.Get(_contract))
			Next
			TContract(clone).clone = 1
			clone.botched = 0
			clone.finished = 0
			clone.owner = 0
			Return clone
		EndIf
	End Function

	Method RemoveContract(_contract:TContract)
		Local contract:TContract = Null
		For Local i:Int = 0 To self.Contracts.Count()-1
			contract = TContract(self.Contracts.Items[i] )
			If contract <> Null AND contract.title = _contract.title and contract.senddate = _contract.senddate and contract.sendtime = _contract.sendtime
				self.Contracts.RemoveByIndex(i)
			EndIf
		Next
	End Method

	Method GetPreviousContractCount:Int(_contract:TContract)
		Local count:Int = 1
		If Not self.Contracts Then self.Contracts = TObjectList.Create(1000)
		Local contract:TContract = Null
		For Local i:Int = 0 To self.Contracts.Count()-1
			contract = TContract(self.Contracts.Items[i] )
			If contract.title = _contract.title And contract.botched <> 1
				contract.spotnumber = count
				count :+ 1
			EndIf
		Next
		Return count
	End Method

	Method RenewContractCount:Int(_contract:TContract)
		Local count:Int = 1
		Local contract:TContract = Null
		For Local i:Int = 0 To self.Contracts.Count()-1
			contract = TContract(self.Contracts.items[i] )
			If contract.title = _contract.title
				If contract.botched <> 1
					contract.spotnumber = count
					count :+1
				else
					contract.spotnumber = 0
				EndIf
			EndIf
		Next
	End Method
End Type



'holds all Programmes a player possesses
Type TPlayerProgrammeCollection' Extends TProgramme
 Field List:TList			= CreateList()
 Field NewsList:TList		= CreateList()
 Field MovieList:TList		= CreateList()
 Field SeriesList:TList		= CreateList()
 Field ContractList:TList	= CreateList()

  Method ClearLists()
	List.Clear()
	NewsList.Clear()
	MovieList.Clear()
	SeriesList.Clear()
	ContractList.Clear()
  End Method

  Method GetOriginalProgramme:TProgramme(_programme:TProgramme)
    If _Programme <> Null
	  For Local Programme:TProgramme = EachIn List
        If Programme.title = _programme.title And Programme.episodeNumber = _programme.episodeNumber
          Return Programme
       	  Exit
        End If
      Next
	EndIf
  End Method

'  Method TopicalityToProgrammeClones:Int(_programme:TProgramme, _list:TList)
  Method TopicalityToProgrammeClones:Int(_programme:TProgramme,_list:TObjectList)
    If _programme <> Null
	  Local Programme:TProgramme = Null
	  For Local i:Int = 0 To _list.Count()-1
	    Programme = TProgramme(_list.Items[i] )
'	    Programme = TProgramme(_list.ValueAtIndex(i))
        If Programme.title = _programme.title And Programme.isMovie 'and Programme.episode = _programme.episode
          Programme.topicality = _programme.topicality
          'DebugLog "aktualisiert..."+Programme.title
        End If
      Next
	EndIf
  End Method

  'removes Contract from Collection (Advertising-Menu in Programmeplanner)
  Method RemoveOriginalContract(_contract:TContract)
    If _contract <> Null
	  For Local contract:TContract = EachIn ContractList
	    Print contract.title + " = " +_contract.title + " and contract.clone = "+contract.clone
        If contract.title = _contract.title And contract.clone = 0
	      'Print "removing contract:"+contract.title
     	  ContractList.Remove(contract)
     	  Exit
        End If
      Next
	EndIf
  End Method

  Method AddNews:Int(news:TNews, owner:Int = 0 )
    If news <> Null
      If owner = 0 Then owner = game.playerID
      news.owner = owner
	  NewsList.AddLast(news)
	EndIf
   End Method

  Method RemoveProgramme:Int(programme:TProgramme, owner:Int=0)
    If programme <> Null
  	  'Print "removed programme:"+programme.title
	  List.remove(programme)
	  MovieList.remove(programme)
	EndIf
  End Method

  Method AddMovie:Int(movie:TProgramme, owner:Int=0)
    If movie <> Null
      movie.used = owner
      MovieList.AddLast(movie)
      List.AddLast(movie)
      'Print "added to collection: "+movie.title + " with Blocks:"+movie.blocks
	EndIf
  End Method

  Method AddContract:Int(contract:TContract, owner:Int=0)
    If contract <> Null
      contract.owner = owner
      'Print "Contract: set to owner "+owner
      contract.calculatedMinAudience = contract.GetMinAudienceNumber(contract.minaudience)
      'DebugLog contract.calculatedMinAudience + " ("+contract.GetMinAudiencePercentage(contract.minaudience)+"%)"
      Self.ContractList.AddLast(contract)
  	  TContractBlocks.Create(contract, 1,owner)
	EndIf
  End Method

  Method AddProgramme:Int(programme:TProgramme, owner:Int = 0)
    If programme <> Null
      programme.used = owner
      If programme.isMovie Then MovieList.AddLast(programme) Else SeriesList.AddLast(programme)
      List.AddLast(programme)
	EndIf
  End Method

  Method AddSerie:Int(serie:TProgramme, owner:Int=0)
    If serie <> Null
      serie.used = owner
      SeriesList.AddLast(serie)
      List.AddLast(serie)
	EndIf
  End Method

  'GetLocalRandom... differs from GetRandom... for using it's personal programmelist
  'instead of the global one
  'returns a movie out of the players programmebouquet
  Method GetLocalRandomMovie:TProgramme()
	Local movie:TProgramme
	movie = TProgramme(MovieList.ValueAtIndex(Rnd(0, CountList(MovieList)-1)))
	Return movie
  End Method

  Method GetLocalRandomSerie:TProgramme()
 	Local serie:TProgramme
	serie = TProgramme(SeriesList.ValueAtIndex(Rnd(0, CountList(SeriesList)-1)))
	Return serie
  End Method

  Method GetLocalRandomContract:TContract()
 	Local contract:TContract
	contract = TContract(ContractList.ValueAtIndex(Rnd(0, CountList(ContractList)-1)))
	Return contract
  End Method

  Method GetProgramme:TProgramme(number:Int)
    For Local obj:TProgramme = EachIn Self.List
	  If Obj.pid = number Then Return obj
    Next
    Return Null
  End Method

  Method GetContract:TContract(number:Int)
    For Local contract:TContract=EachIn Self.ContractList
	  If contract.id = number Then Return contract
    Next
    'Print "getcontract: contract not found"
    Return Null
  End Method

  Method GetMovieFromCollection:TProgramme(number:Int)
   For Local movie:TProgramme=EachIn MovieList
	 If movie.pid = number Then Return movie
   Next
   Return Null
 End Method

  Method GetSeriesFromCollection:TProgramme(number:Int)
   For Local movie:TProgramme=EachIn SeriesList
	 If movie.pid = number Then Return movie
   Next
   Return Null
 End Method

End Type


Type TProgrammeElement
	Field title:string
	Field description:string
	Field id:int = 0

	Method BaseInit(title:string, description:string, id:int)
		self.title = title
		self.description = description
		self.id = id
	End Method
End Type

'ad-contracts
Type TContract extends TProgrammeElement
  Field daystofinish:Int
  Field spotcount:Int
  Field spotssent:Int
  Field spotnumber:Int = -1
  Field botched:Int =0
  Field senddate:Int = -1
  Field sendtime:Int = -1
  Field targetgroup:Int
  Field minaudience:Int
  Field profit:Int
  Field finished:Int =0
  Field clone:Int = 0 'is it a clone (used for adblocks) or the original one (contract-gfxlist)
  Field penalty:Int
  Field owner:Int = 0
  Field daysigned:Int 'day the contract has been taken from the advertiser-room
  Field calculatedProfit:Int =0
  Field calculatedPenalty:Int =0
  Field calculatedMinAudience:Int =0

  Global List:TList = CreateList() {saveload = "special"}
  Global MinAudienceMultiplicator:Double = 1000000 {saveload = "special"}


	Function Load:TContract(pnode:xmlNode)
		Local Contract:TContract = New TContract
		Local NODE:xmlNode = pnode.FirstChild()
		While NODE <> Null
			Local nodevalue:String = ""
			If NODE.Name = Upper("MINAUDIENCEMULTIPLICATOR")
				TContract.MinAudienceMultiplicator = Double(node.Attribute("var").Value)
			EndIf
			If NODE.Name = Upper("CONTRACTS")
				If node.HasAttribute("var", False) Then nodevalue = node.Attribute("var").value
				Local typ:TTypeId = TTypeId.ForObject(StationMap)
				For Local t:TField = EachIn typ.EnumFields()
					If t.MetaData("saveload") <> "special" And Upper(t.name()) = NODE.name
						t.Set(Contract, nodevalue)
					EndIf
				Next
				If contract.owner > 0 And contract.owner <= 4
				    If contract.clone > 0 Then Player[contract.owner].ProgrammePlan.AddContract(contract)
				    If contract.clone = 0 Then Player[contract.owner].ProgrammeCollection.AddContract(contract)
				EndIf
				If contract.clone = 0 Then TContract.List.AddLast(contract)
			EndIf
			NODE = NODE.nextSibling()
		Wend
		Return contract
	End Function

	Function LoadAll()
		PrintDebug("TContract.LoadAll()", "Lade Werbeverträge", DEBUG_SAVELOAD)
		TContract.List.Clear()
		Local Children:TList = LoadSaveFile.NODE.ChildList
		For Local node:xmlNode = EachIn Children
			If NODE.name = "ALLCONTRACTS"
			      TContract.Load(NODE)
			End If
		Next
	End Function

	Function SaveAll()
		LoadSaveFile.xmlBeginNode("ALLCONTRACTS")
			LoadSaveFile.xmlWrite("MINAUDIENCEMULTIPLICATOR", TContract.MinAudienceMultiplicator)
   			For Local Contract:TContract = EachIn TContract.List
     			Contract.Save()
   			Next
   		LoadSaveFile.xmlCloseNode()
	End Function

	Method Save()
		LoadSaveFile.xmlBeginNode("CONTRACT")
 			Local typ:TTypeId = TTypeId.ForObject(Self)
			For Local t:TField = EachIn typ.EnumFields()
				If t.MetaData("saveload") <> "special" Then LoadSaveFile.xmlWrite(Upper(t.name()), String(t.Get(Self)))
			Next
		LoadSaveFile.xmlCloseNode()
	End Method

  Function Create:TContract(title$, description$, daystofinish:Int, spotcount:Int, targetgroup:Int, minaudience:Int, profit:Int, penalty:Int, id:Int=0, owner:Int = 0)
    Local contract:TContract =New TContract
    contract.BaseInit(title, description, id)
    contract.daystofinish = daystofinish
    contract.spotcount = spotcount
    contract.spotssent = 0
    contract.owner = owner
    contract.spotnumber =  1
    contract.targetgroup = targetgroup
    contract.minaudience = minaudience
    contract.profit      = profit
    contract.penalty     = penalty
    contract.daysigned   = -1

	If Not List Then List = CreateList()
	List.AddLast(contract)
	'SortList List
	SortList(List)
	Return contract
  End Function

  Function CalculateMinAudienceMultiplicator()
		Local maxaudience:Int = 0
		For Local MyPlayer:TPlayer = EachIn TPlayer.List
			If MyPlayer.maxaudience > maxaudience Then maxaudience = MyPlayer.maxaudience
		Next
		If maxaudience <=  50000 Then MinAudienceMultiplicator =   20000
		If maxaudience >   50000 Then MinAudienceMultiplicator =   50000
		If maxaudience >  100000 Then MinAudienceMultiplicator =  100000
		If maxaudience >  250000 Then MinAudienceMultiplicator =  250000
		If maxaudience >  500000 Then MinAudienceMultiplicator =  500000
		If maxaudience > 1000000 Then MinAudienceMultiplicator = 1000000
		If maxaudience > 5000000 Then MinAudienceMultiplicator = 5000000
		If maxaudience >10000000 Then MinAudienceMultiplicator =10000000
  End Function

   'up to now only for creation of playerbouquet (not for listing in advertiserroom)
	Function GetRandomContract:TContract()
		CalculateMinAudienceMultiplicator()
		Local contract:TContract = Null
		Repeat contract = TContract(List.ValueAtIndex(Rnd(0, CountList(List) - 1)))
		Until contract.daysigned = -1 And contract.owner = 0
		contract.daysigned = Game.day
		contract.calculatedMinAudience = contract.CalculateMinAudience()
		contract.calculatedProfit = contract.CalculatePrice(contract.profit)
		contract.calculatedPenalty = contract.CalculatePrice(contract.penalty)
		Return contract
	End Function

  Function GetMinAudiencePercentage:Float(dbvalue:Int)
  	If dbvalue=0   Then Return 0
  	If dbvalue=25  Then Return 0.01
  	If dbvalue=50  Then Return 0.025
  	If dbvalue=75  Then Return 0.05
  	If dbvalue=100 Then Return 0.075
  	If dbvalue=125 Then Return 0.15
  	If dbvalue=150 Then Return 0.3
  	If dbvalue=175 Then Return 0.5
  	If dbvalue=200 Then Return 0.75
  	If dbvalue=225 Then Return 0.9
    Return 0
  End Function

  'multiplies basevalues of prices, values are from 0 to 255 for 1 spot... per 1000 people in audience
  'if targetgroup is set, the price is doubled
  Method CalculatePrice:Float(baseprice:Int=0)
    Local price:Float = 0
	Local audiencepercentage:Float = TContract.GetMinAudiencePercentage(minaudience)
	If audiencepercentage <= 0.05 Then audiencepercentage = 0.05
    price = baseprice * 1000 *audiencepercentage* spotcount
    Return price
  End Method

  'multiplies basevalues of prices, values are from 0 to 255 for 1 spot... per 1000 people in audience
  'if targetgroup is set, the price is doubled
  Method CalculateMinAudience:Float()
    Return TContract.MinAudienceMultiplicator * TContract.GetMinAudiencePercentage(minaudience)
  End Method

  Method GetMinAudienceNumber:Float(dbvalue:Int)
'    If owner <= 0 Then Return Player[Game.playerID].maxaudience * TContract.GetMinAudiencePercentage(dbvalue)
'    Return Player[owner].maxaudience * TContract.GetMinAudiencePercentage(dbvalue)
     If calculatedMinAudience = 0 Then calculatedMinAudience = CalculateMinAudience()
     Return calculatedMinAudience
'    Return TContract.MinAudienceMultiplicator * TContract.GetMinAudiencePercentage(dbvalue)
  End Method

  Function GetTargetgroupName:String(group:Int)
    If group = -1 Then Return "Keine"
    If group = 1  Then Return "Kinder"
    If group = 2  Then Return "Jugendliche"
    If group = 3  Then Return "Hausfrauen"
    If group = 4  Then Return "Arbeitnehmer"
    If group = 5  Then Return "Arbeitslose"
    If group = 6  Then Return "Manager"
    If group = 7  Then Return "Rentner"
    If group = 8  Then Return "Frauen"
    If group = 9  Then Return "Männer"
    Return "Keine"
  End Function

  Method getDaysToFinish:Int()
	Return (daystofinish-(Game.day - daysigned))
  End Method

 Method ShowSheet:Int(x:Int,y:Int, plannerday:Int = -1)
    Local calcminaudience:Int = GetMinAudienceNumber(minaudience)
 	gfx_datasheets_contract.render(x,y)
	'DrawImage gfx_datasheets_contract,x,y
	local font:TBitmapFont = FontManager.basefont
	FontManager.basefontBold.drawBlock(title 	       , x+10 , y+11  , 270, 70,0, 0,0,0, 0,1)  'prints title on moviesheet
 	font.drawBlock(description      , x+10 , y+33 , 270, 70) 'prints programmedescription on moviesheet
 	font.drawBlock(Localization.GetString("AD_PROFIT")+": "       , x+10 , y+94 , 130, 16)
 	font.drawBlock(functions.convertValue(String(calculatedProfit), 2, 0) , x+10 , y+94 , 130, 16,2)
 	font.drawBlock(Localization.GetString("AD_TOSEND")+": "    , x+150, y+94 , 127, 16)
 	font.drawBlock(spotcount+"/"+spotcount , x+150, y+91 , 127, 19,2)
 	font.drawBlock(Localization.GetString("AD_PENALTY")+": "       , x+10 , y+117, 130, 16)
 	font.drawBlock(functions.convertValue(String(calculatedPenalty), 2, 0), x+10 , y+117, 130, 16,2)
 	font.drawBlock(Localization.GetString("AD_MIN_AUDIENCE")+": "    , x+150, y+117, 127, 16)
 	font.drawBlock(functions.convertValue(String(calcminaudience), 2, 0), x+150, y+117, 127, 16,2)
 	font.drawBlock(Localization.GetString("AD_TARGETGROUP")+": "+GetTargetgroupName(targetgroup)   , x+10 , y+140 , 270, 16)
 	If getDaysToFinish() = 0
 	  font.drawBlock(Localization.GetString("AD_TIME")+": "+Localization.GetString("AD_TILL_TODAY") , x+86 , y+163 , 126, 16)
 	Else If getDaysToFinish() = 1
 	  font.drawBlock(Localization.GetString("AD_TIME")+": "+Localization.GetString("AD_TILL_TOMORROW") , x+86 , y+163 , 126, 16)
 	Else
 	  font.drawBlock(Localization.GetString("AD_TIME")+": "+Replace(Localization.GetString("AD_STILL_X_DAYS"),"%1", (daystofinish-(Game.day - daysigned))), x+86 , y+163 , 122, 16)
 	EndIf
 End Method

	Function GetContract:TContract(number:Int)
		For Local contract:TContract = EachIn List
			If contract.id = number
				'CalculateMinAudienceMultiplicator()
				Return contract
			EndIf
		Next
   Return Null
 End Function

End Type

Type TProgramme extends TProgrammeElement 'parent of movies, series and so on
 Field clone:Int = 0
 Field actors:String
 Field director:String
 Field country:String
 Field year:Int
 Field livehour:Int
 Field Outcome:Float
 Field review:Float
 Field speed:Float
 Field relPrice:Int
 Field Genre:Int
 Field episodecount:Int 	= 0
 Field blocks:Int
 Field fsk18:String
 Field isMovie:Int			= 1
 Field episodeNumber:Int	= 0
 Field topicality:Int		= -1 				'how "attractive" a movie is (the more shown, the less this value)
 Field maxtopicality:Int 	= 255
 Field pid:Int = 0
 Field episodeList:TList = CreateList()  ' TObjectList = TObjectList.Create(100) {saveload = "nosave"}
 Field used:Int = 0
 Field senddate:Int = -1				'which day this programme is planned to be send?
 Field sendtime:Int = -1 				'which time this programme is planned to be send?

 Global ProgList:TList = CreateList()   'TObjectList =  TObjectList.Create(1000) {saveload = "nosave"}
 Global ProgMovieList:TList = CreateList()   'TObjectList = TObjectList.Create(1000) {saveload = "nosave"}
 Global ProgSeriesList:TList = CreateList()  'TObjectList = TObjectList.Create(1000) {saveload = "nosave"}


	Function Load:TProgramme(pnode:xmlNode, isEpisode:Int = 0, origowner:Int = 0)
		Local Programme:TProgramme = New TProgramme
		Programme.episodeList = CreateList() ' TObjectList.Create(100)

		Local NODE:xmlNode = pnode.FirstChild()
		While NODE <> Null
			Local nodevalue:String = ""
			If node.HasAttribute("var", False) Then nodevalue = node.Attribute("var").value
			Local typ:TTypeId = TTypeId.ForObject(Programme)
			For Local t:TField = EachIn typ.EnumFields()
				If (t.MetaData("saveload") <> "nosave" Or t.MetaData("saveload") = "normal") And Upper(t.name()) = NODE.name
					t.Set(Programme, nodevalue)
				EndIf
			Next
			Select NODE.name
				Case "EPISODE"
    						     Programme.EpisodeList.AddLast(TProgramme.Load(NODE, 1, Programme.used))
			End Select
			NODE = NODE.nextSibling()
		Wend
		If Programme.episodecount > 0 And Not isEpisode
			' Print "loaded series: "+Programme.title
			TProgramme.ProgSeriesList.AddLast(Programme)
		Else If Not isEpisode
			TProgramme.ProgMovieList.AddLast(Programme)
			'Print "loaded  movie: "+Programme.title
		EndIf
		TProgramme.ProgList.AddLast(Programme)
		If Programme.used > 0 Or Programme.clone Then
			Player[Programme.used].ProgrammeCollection.AddProgramme(Programme, Programme.used)
			'Print "added to player:"+Programme.used + " ("+Programme.title+") Clone:"+Programme.clone + " Time:"+Programme.sendtime
		EndIf
		If isEpisode And origowner > 0 Then
			Player[origowner].ProgrammeCollection.AddProgramme(Programme, origowner)
			'Print "added to player:"+Programme.used
		EndIf
		Return programme
	End Function

  Function LoadAll()
	PrintDebug("TProgramme.LoadAll()", "Lade Programme", DEBUG_SAVELOAD)
    ProgList.Clear()
	ProgMovieList.Clear()
	ProgSeriesList.Clear()
	Local Children:TList = LoadSaveFile.NODE.ChildList
	For Local NODE:xmlNode = EachIn Children
		If NODE.name = "PROGRAMME"
		      TProgramme.Load(NODE)
		End If
	Next
  End Function

	Function SaveAll()
		Local Programme:TProgramme
		Local i:Int = 0
		LoadSaveFile.xmlBeginNode("ALLPROGRAMMES")
			For i = 0 To TProgramme.ProgMovieList.Count()-1
				Programme = TProgramme(TProgramme.ProgMovieList.ValueAtIndex(i))
'				Programme = TProgramme(TProgramme.ProgMovieList.Items[i] )
				If Programme <> Null Then Programme.Save()
			Next
			For i = 0 To TProgramme.ProgSeriesList.Count()-1
'				Programme = TProgramme(TProgramme.ProgSeriesList.Items[i])
				Programme = TProgramme(TProgramme.ProgSeriesList.ValueAtIndex(i))
				If Programme <> Null Then Programme.Save()
			Next
	 	LoadSaveFile.xmlCloseNode()
	End Function

	Method Save(isepisode:Int=0)
	    If Not isepisode Then LoadSaveFile.xmlBeginNode("PROGRAMME")
			Local typ:TTypeId = TTypeId.ForObject(Self)
			For Local t:TField = EachIn typ.EnumFields()
				If t.MetaData("saveload") <> "nosave" Or t.MetaData("saveload") = "normal"
					LoadSaveFile.xmlWrite(Upper(t.name()), String(t.Get(Self)))
				EndIf
			Next
			'SaveFile.WriteInt(Programme.episodeList.Count()-1)
			If Not isepisode
				For Local j:Int = 0 To Self.episodeList.Count()-1
					LoadSaveFile.xmlBeginNode("EPISODE")
						TProgramme(Self.episodeList.ValueAtIndex(j)).Save(True)
'						TProgramme(Self.episodeList.Items[j] ).Save(True)
					LoadSaveFile.xmlCloseNode()
				Next
			EndIf
		If Not isepisode Then LoadSaveFile.xmlCloseNode()
	End Method

 Method Buy()
   Player[Game.playerID].finances[TFinancials.GetDayArray(Game.day)].PayMovie(ComputePrice())
   'DebugLog "Programme "+title +" bought"
 End Method

 Method Sell()
   Player[Game.playerID].finances[TFinancials.GetDayArray(Game.day)].SellMovie(ComputePrice())
   'DebugLog "Programme "+title +" sold"
 End Method

 Function CountGenre:Int(Genre:Int, Liste:TList)
      Local genrecount:Int=0
      For Local movie:TProgramme= EachIn Liste
      	If movie.Genre = Genre genrecount:+1
      Next
      Return genrecount
 End Function

	Function GetProgramme:TProgramme(number:Int)
		For Local i:Int = 0 To ProgList.Count() - 1
			If TProgramme(ProgList.ValueAtIndex(i)) <> Null
				If TProgramme(ProgList.ValueAtIndex(i)).pid = number Then Return TProgramme(ProgList.ValueAtIndex(i))
			EndIf
		Next
		Return Null
	End Function

	Function GetMovie:TProgramme(number:Int)
		For Local i:Int = 0 To ProgMovieList.Count() - 1
			If TProgramme(ProgMovieList.ValueAtIndex(i)) <> Null
				If TProgramme(ProgMovieList.ValueAtIndex(i)).pid = number Then Return TProgramme(ProgMovieList.ValueAtIndex(i))
			EndIf
		Next
		Return Null
	End Function

	Function GetEpisode:TProgramme(parentprogramme:TProgramme, number:Int)
		If parentprogramme <> Null
			For Local i:Int = 0 To parentprogramme.episodeList.Count() - 1
				If TProgramme(parentprogramme.episodeList.ValueAtIndex(i)).pid = number Then Return TProgramme(parentprogramme.episodeList.ValueAtIndex(i))
			Next
		EndIf
		Return Null
	EndFunction

	Function GetSeries:TProgramme(number:Int)
		For Local i:Int = 0 To ProgSeriesList.Count() - 1
			If TProgramme(ProgSeriesList.ValueAtIndex(i)).pid = number Then Return TProgramme(ProgSeriesList.ValueAtIndex(i))
		Next
		Return Null
	End Function

	Function GetRandomMovie:TProgramme(playerID:Int = -1)
		Local movie:TProgramme
		Local Count:Int = 0
		Repeat
		  movie = TProgramme(ProgMovieList.ValueAtIndex(Rnd(0, ProgMovieList.Count() - 1)))
		  Count:+1
		Until movie.used = 0 Or Count > 100
		If Count < 100 Then movie.used = playerID;Return movie
		Return Null
	End Function

	Function GetRandomMovieWithMinPrice:TProgramme(MinPrice:Int, playerID:Int = -1)
		Local movie:TProgramme
		Local count:Int=0
		Repeat
		  movie = TProgramme(ProgMovieList.ValueAtIndex(Rnd(0, ProgMovieList.Count() - 1)))
'		  movie = TProgramme(ProgMovieList.items[(Rnd(0, ProgMovieList.Count()-1))])
		  count:+1
		Until (movie.ComputePrice() >= MinPrice And movie.used = 0 )Or count > 100
		If Count < 100 Then movie.used = playerID;Return movie
		Return Null
	End Function

	Function GetRandomMovieWithBlocks:TProgramme(playerID:Int = -1, blocks:Int = 0)
		Local movie:TProgramme
		Local count:Int=0
		Repeat
'			movie = TProgramme(ProgMovieList.items[(Rnd(0, ProgMovieList.Count() - 1))] )
			movie = TProgramme(ProgMovieList.ValueAtIndex((Rnd(0, ProgMovieList.Count() - 1))))
			Count:+1
		Until movie.used = 0 And movie.blocks = blocks
		movie.used = playerID Or Count > 50 'hier spaeter auf playerid
		Return movie
	End Function

	Function GetRandomSerie:TProgramme(playerID:Int = -1)
		Local serie:TProgramme
		Local count:Int=0
		Repeat
			serie = TProgramme(ProgSeriesList.ValueAtIndex((Rnd(0, ProgSeriesList.Count() - 1))))
			Count:+1
		Until serie.used = 0 Or Count > 100
		If Count < 100
			serie.used = playerID
			Return serie
		endif
		'print "KEINE SERIE FÜR "+playerID+" verfügbar"
		Return Null
	End Function

	Function GetGenre:String(Genre:Int)
		Return Localization.GetString("MOVIE_GENRE_" + Genre)
	End Function

	Method ComputeTopicality:Float()
		If topicality < 0
			Return (255 - 2 * (Game.year - year))   'simplest form ;D
		Else
			Return topicality
		EndIf
	End Method

 'computes a percentage which could be multiplied with maxaudience
 Method ComputeAudienceQuote:Float(lastquote:Float=0)
    Local quote:Float =0.0
    Local singleprice:Int = 0
    singleprice = ComputePrice()
    If episodecount > 0 Then singleprice = singleprice / episodecount
    quote = 0.25*lastquote + 0.2*Outcome/255 + 0.15*review/255 + 0.1*speed/255 + 0.2*ComputeTopicality()/255 + 0.1*(RandRange(1,254)+1)/255
    Return quote * Game.maxAudiencePercentage
 End Method

	Method RefreshTopicality:Int()
		topicality:*1.5
		If topicality > maxtopicality Then topicality = maxtopicality
		Return topicality
	End Method

	Method ComputePrice:Int()
		Local value:Float
		Local tmpreview:Float
		Local tmpspeed:Float

		If Outcome > 0
			value = 0.45 * 255 * Outcome + 0.25 * 255 * review + 0.3 * 255 * speed
			If (maxTopicality > 220) Then value:*1.5
			If (maxTopicality > 240) Then value:*1.5
		Else
			value = 0.4 * 255 * review + 0.6 * 255 * speed
			tmpreview = 1.6667 * review
			If (review > 0.5 * 255) Then tmpreview = 255 - 2.5 * (review - 0.5 * 255)
			tmpspeed = 1.6667 * speed
			If (speed > 0.6 * 255) Then tmpspeed = 255 - 2.5 * (speed - 0.6 * 255)
			value = 0.4 * 255 * tmpreview + 0.6 * 255 * tmpspeed
			value:*(episodecount * 0.75)
		EndIf
		value:*(3 * ComputeTopicality() / 255)
		Return Int(Floor(value / 1000) * 1000)
	End Method

	Method ShowSheet:Int(x:Int,y:Int, plannerday:Int = -1, series:TProgramme=null)
		Local widthbarspeed:Float		= Float(speed / 255)
		Local widthbarreview:Float		= Float(review / 255)
		Local widthbaroutcome:Float		= Float(Outcome/ 255)
		Local widthbartopicality:Float	= Float(Float(topicality) / 255)
		local normalFont:TBitmapFont	= FontManager.baseFont

		local dY:int = 0

		If isMovie
			gfx_datasheets_movie.render(x,y)
		else
			gfx_datasheets_series.render(x,y)
			'episode display
			if series <> null
				episodecount = series.episodecount
				If year <= 0 Then year = series.year
				normalFont.DrawBlock("(" + episodeNumber + "/" + series.episodecount + ") " + title, x + 10, y + 34, 278, 20, 0)  'prints programmedescription on moviesheet
			else
				normalFont.DrawBlock(episodecount+" "+Localization.GetString("MOVIE_EPISODES") , x+10,  y+34 , 278, 20,0) 'prints programmedescription on moviesheet
			endif

			dy :+ 22
		endif
		FontManager.basefontBold.DrawBlock(title, x + 10, y + 11, 278, 20)
		If(fsk18 = "FSK18") then normalFont.DrawBlock(Localization.GetString("MOVIE_XRATED") , x+240 , y+dY+34 , 50, 20,0) 'prints pg-rating

		normalFont.DrawBlock(description      , x+10,  y+dy+56 , 278, 70,0) 'prints programmedescription on moviesheet
		normalFont.DrawBlock(Localization.GetString("MOVIE_DIRECTOR")+":", x+10 , y+dY+135, 280, 16,0)
		normalFont.DrawBlock(Localization.GetString("MOVIE_ACTORS")+":"  , x+10 , y+dY+148, 280, 32,0)
		normalFont.DrawBlock(Localization.GetString("MOVIE_SPEED")       , x+222, y+dY+187, 280, 16,0)
		normalFont.DrawBlock(Localization.GetString("MOVIE_CRITIC")      , x+222, y+dY+210, 280, 16,0)
		normalFont.DrawBlock(Localization.GetString("MOVIE_BOXOFFICE")   , x+222, y+dY+233, 280, 16,0)
		normalFont.DrawBlock(director         , x+10 +5+ normalFont.getWidth(Localization.GetString("MOVIE_DIRECTOR")+":") , y+dY+135, 280-15-normalFont.getWidth(Localization.GetString("MOVIE_DIRECTOR")+":"), 16,0) 	'prints director
		normalFont.DrawBlock(actors           , x+10 +5+ normalFont.getWidth(Localization.GetString("MOVIE_ACTORS")+":"), y+dY+148, 280-15-normalFont.getWidth(Localization.GetString("MOVIE_ACTORS")+":"), 32,0) 	'prints actors
		normalFont.DrawBlock(GetGenre(Genre)  , x+78 , y+dY+35 , 150, 16,0) 	'prints genre
		normalFont.DrawBlock(country          , x+10 , y+dY+35 , 150, 16,0)		'prints country
		normalFont.DrawBlock(year		      , x+36 , y+dY+35 , 150, 16,0) 	'prints year

		normalFont.DrawBlock(Localization.GetString("MOVIE_TOPICALITY")  , x+84, y+281, 40, 16,0)
		normalFont.DrawBlock(Localization.GetString("MOVIE_BLOCKS")+": "+blocks, x+10, y+281, 100, 16,0)
		normalFont.DrawBlock(ComputePrice(), x+240, y+281, 120, 20,0)


		If widthbarspeed  >0.01 then Assets.GetSprite("gfx_datasheets_bar").DrawClipped(x+13 - 200 + widthbarspeed*200,	y+dY+188,		x+13, y+dY+187, 200, 12)
		If widthbarreview >0.01 then Assets.GetSprite("gfx_datasheets_bar").DrawClipped(x+13 - 200 + widthbarreview*200,y+dY+210,		x+13, y+dY+209, 200, 12)
		If widthbaroutcome>0.01 then Assets.GetSprite("gfx_datasheets_bar").DrawClipped(x+13 - 200 + widthbaroutcome*200,y+dY+232,		x+13, y+dY+231, 200, 12)
		If widthbartopicality>0.01 then Assets.GetSprite("gfx_datasheets_bar").DrawClipped(x+115 - 200 + widthbartopicality*100,y+280,	x+115, y+279, 100,12)
	End Method
 End Type

Type TNews extends TProgrammeElement
  Field Genre:Int
  Field quality:Int
  Field price:Int
  Field episodecount:Int = 0
  Field episode:Int = 0
  Field maxepisodes:Int = 0
  Field episodeList:TList 	{saveload="special"}
  Field happenedday:Int = -1
  Field happenedhour:Int = -1
  Field happenedminute:Int = -1
  Field parentNews:TNews = Null
  Field sendposition:Int = 0
  Field owner:Int = 0 				'who is the owner of this newscopy?
  Field used : Int = 0  			'event happened, so this news is not repeated until every else news is used
  Global LastUniqueID:Int = 0 {saveload="special"}
  Global List:TList = CreateList()  {saveload="special"}' :TObjectList = TObjectList.Create(1000)     'holding only first chain of news (start)
  Global NewsList:TList = CreateList()  {saveload="special"} ':TObjectList = TObjectList.Create(1000) 'holding all news


	Function Load:TNews(pnode:xmlNode, isEpisode:Int = 0, origowner:Int = 0)
		Local News:TNews = New TNews
		Local ParentNewsID:Int = -1
		News.episodeList = CreateList() ' TObjectList.Create(100)

		Local NODE:xmlNode = pnode.FirstChild()
		While NODE <> Null
			Local nodevalue:String = ""
			If node.HasAttribute("var", False) Then nodevalue = node.Attribute("var").value
			Local typ:TTypeId = TTypeId.ForObject(News)
			For Local t:TField = EachIn typ.EnumFields()
				If (t.MetaData("saveload") <> "nosave" And t.MetaData("saveload") <> "special") And Upper(t.name()) = NODE.name
					t.Set(News, nodevalue)
				EndIf
			Next
			Select NODE.name
				Case "LASTUNIQUEID"
								TNews.LastUniqueID = Int(node.Attribute("var").Value)
				Case "PARENTNEWSID"
								ParentNewsID = Int(node.Attribute("var").Value)
				Case "EPISODE"
    						     News.EpisodeList.AddLast(TProgramme.Load(NODE, 1, News.owner))
			End Select
			NODE = NODE.nextSibling()
		Wend
	  	If ParentNewsID >= 0 Then news.parentNews = TNews.GetNews(parentNewsID)
   	    TNews.NewsList.AddLast(news)
		If Not IsEpisode Then TNews.List.AddLast(news)
		Return news
	End Function

	Function LoadAll()
		PrintDebug("TNews.LoadAll()", "Lade News", DEBUG_SAVELOAD)
		TNews.List.Clear()
	    TNews.NewsList.Clear()
		Local Children:TList = LoadSaveFile.NODE.ChildList
		For Local node:xmlNode = EachIn Children
			If NODE.name = "ALLNEWS"
			      TNews.Load(NODE)
			End If
		Next
	End Function

	Function SaveAll()
		Local i:Int = 0
		LoadSaveFile.xmlBeginNode("ALLNEWS")
			LoadSaveFile.xmlWrite("LASTUNIQUEID",	TNews.LastUniqueID)
			For i = 0 To TNews.List.Count()-1
				Local news:TNews = TNews(TNews.List.ValueAtIndex(i))
				If news <> Null Then news.Save()
			Next
		LoadSaveFile.xmlCloseNode()
	End Function

	Method Save(isEpisode:Int=0)
	    If Not isepisode Then LoadSaveFile.xmlBeginNode("NEWS")
			Local typ:TTypeId = TTypeId.ForObject(Self)
			For Local t:TField = EachIn typ.EnumFields()
				If t.MetaData("saveload") <> "special" Or t.MetaData("saveload") = "normal"
					LoadSaveFile.xmlWrite(Upper(t.name()), String(t.Get(Self)))
				EndIf
			Next
			If Not isepisode
				For Local j:Int = 0 To Self.episodeList.Count()-1
					LoadSaveFile.xmlBeginNode("EPISODE")
						TNews(Self.episodeList.ValueAtIndex(j)).Save(True)
					LoadSaveFile.xmlCloseNode()
				Next
			EndIf
		If Not isepisode Then LoadSaveFile.xmlCloseNode()
	End Method


  Function CountGenre:Int(Genre:Int, Liste:TList)
    Local genrecount:Int=0
    For Local news:TNews= EachIn Liste
      If news.Genre = Genre genrecount:+1
    Next
    Return genrecount
 End Function

  Function GetRandomNews:TNews()
    Local news:TNews = Null
    Local allsent:Int = 0
    Repeat news = TNews(List.ValueAtIndex((Rnd(0, List.Count() - 1))))
'    Repeat news = TNews(List.items[(Rnd(0, List.Count()-1))])
      allsent:+1
    Until news.used = 0 Or allsent > 250
    If allsent > 250
	  For Local i:Int = 0 To List.Count()-1
'        news = TNews(List.Items[i])
        news = TNews(List.ValueAtIndex(i))
		If news <> Null Then news.used = 0
	  Next
      Print "NEWS: allsent > 250... reset"
'      news = TNews(List.items[(Rnd(0, List.count()-1))])
      news = TNews(List.ValueAtIndex((Rnd(0, List.Count() - 1))))
    End If
  '  news.used = 1
    news.happenedday = game.day
    news.happenedhour = game.GetActualHour()
    news.happenedminute = game.GetActualMinute()
    news.used = 1
    Print "get random news: "+news.title
    Return news
  End Function

  Function GetGenre:String(Genre:Int)
	If Genre = 0 Then Return Localization.GetString("NEWS_POLITICS_ECONOMY")
	If Genre = 1 Then Return Localization.GetString("NEWS_SHOWBIZ")
	If Genre = 2 Then Return Localization.GetString("NEWS_SPORT")
	If Genre = 3 Then Return Localization.GetString("NEWS_TECHNICS_MEDIA")
	If Genre = 4 Then Return Localization.GetString("NEWS_CURRENTAFFAIRS")
 	Return Genre+ " unbekannt"
  End Function

  Method ComputeTopicality:Float()
    Local value:Float
 	value = Int(255-10*((Game.day*10000+game.GetActualHour()*100+game.GetActualMinute()) - (happenedday*10000+happenedhour*100+happenedminute))/100) 'simplest form ;D
    If value < 0 Then value =0
 	Return value
  End Method


 'computes a percentage which could be multiplied with maxaudience
 Method ComputeAudienceQuote:Float(lastquote:Float=0)
    Local quote:Float =0.0
    If lastquote < 0 Then lastquote = 0
    quote = 0.1*lastquote + 0.35*((quality+5)/255) + 0.5*ComputeTopicality()/255 + 0.05*(Rand(254)+1)/255
    Return quote * Game.maxAudiencePercentage
 End Method

  Method ComputePrice:Int()
    Return Floor(Float(quality * price / 100 * 2 / 5)) * 100 + 1000  'Teuerstes in etwa 10000+1000
  End Method

  Function Create:TNews(title:String, description:String, Genre:Int, episode:Int=0, quality:Int=0, price:Int=0, id:Int=0)
	  Local LocObject:TNews =New TNews
	  LocObject.BaseInit(title, description, 30000+TNews.LastUniqueID)
	  LocObject.title       = title
	  LocObject.description = description
	  LocObject.Genre       = Genre
	  LocObject.episode     = episode
	  Locobject.quality     = quality
	  Locobject.price       = Rand(80,100)
	  TNews.LastUniqueID:+1
      LocObject.episodeList = CreateList()
	  List.AddLast(LocObject)
	  NewsList.AddLast(LocObject)
	  Return LocObject
	End Function

  Method AddEpisode:TNews(title:String, description:String, Genre:Int, episode:Int=0,quality:Int=0, price:Int=0, id:Int=0)
	  Local LocObject:TNews =New TNews
	  LocObject.BaseInit(title, description, id)
	  LocObject.Genre       = Genre
	  LocObject.episode     = episode
	  locobject.quality     = quality
	  locobject.price       = price
		Local news:TNews = TNews.GetLast()
        news.episodecount :+ 1
	    LocObject.episode     = news.episodecount

      LocObject.parentNews = Self
	  If Not news.episodeList Then news.episodeList = CreateList()
	  news.episodeList.AddLast(LocObject)
	  SortList(news.episodeList)
	  NewsList.AddLast(LocObject)
	  Return LocObject
	End Method

  Function GetLast:TNews()
		Local LocObject:TNews
'		LocObject = TNews(TNews.List.items[(TNews.List.count()-1)])
		LocObject = TNews(TNews.List.ValueAtIndex(TNews.List.Count() - 1))
		Return LocObject
	End Function

  'returns Parent (first) of a random NewsChain	(genre -1 is random)
  'Important: only unused (happenedday = -1 or older than X days)
  Function GetRandomChainParent:TNews(Genre:Int=-1)
    Local allsent:Int =0
    Local news:TNews=Null
    Repeat news = TNews(List.ValueAtIndex(Rnd(0, List.Count() - 1)))
'    Repeat news = TNews(List.items[Rnd(0, List.count()-1)])
      allsent:+1
    Until news.used = 0 Or allsent > 250
'    If allsent > 250 Then news = TNews(List.items[Rnd(0, List.Count() - 1)] )
    If allsent > 250 Then news = TNews(List.ValueAtIndex(Rnd(0, List.Count() - 1)))

    news.happenedday = game.day
    news.happenedhour = game.GetActualHour()
    news.happenedminute = game.GetActualMinute()
    news.used = 1
    Return news
  EndFunction

  'returns the next news out of a chain, params are the currentnews
  'Important: only unused (happenedday = -1 or older than X days)
  Function GetNextInNewsChain:TNews(currentNews:TNews, isParent:Int=0)
    Local news:TNews=Null
    If currentNews <> Null
      If Not isParent Then news = TNews(currentNews.parentNews.episodeList.ValueAtIndex(currentnews.episode -1))
      If     isParent Then news = TNews(currentNews.episodeList.ValueAtIndex(0))
      news.happenedday = game.day
      news.happenedhour = game.GetActualHour()
      news.happenedminute = game.GetActualMinute()
      news.used = 1
      Return news
    End If
  EndFunction

 Function GetNews:TNews(number:Int)
   Local news:TNews = Null
   For Local i:Int = 0 To TNews.List.Count()-1
     news = TNews(TNews.List.ValueAtIndex(i))
'     news = TNews(TNews.List.Items[ i ])
	 If news <> Null
  	   If news.id = number
         news.happenedday = Game.day
  	     news.happenedhour = Game.GetActualHour()
  	     news.happenedminute = Game.GetActualMinute()
	     Return news
	   EndIf
	 EndIf
   Next
   Return Null
 End Function

  'returns a News which has no newschain (genre -1 is random)
  'Important: only unused (happenedday = -1 or older than X days)
  Function GetASingleNews:TNews(Genre:Int=-1)
  EndFunction

End Type

Type TMovie Extends TProgramme
	Global LastUniqueID:Int = 0
	Function Create:TMovie(title:String, description:String, actors:String, director:String, country:String, year:Int, livehour:Int, Outcome:Float, review:Float, speed:Float, relPrice:Int, Genre:Int, blocks:Int, fsk18:String, id:Int=0, Own:Int=0)
	  Local movie:TMovie =New TMovie
	  movie.BaseInit(title, description, 0)
	  movie.review      = review
	  movie.speed       = speed
	  movie.relPrice    = relPrice
	  movie.Genre       = Genre
	  movie.blocks      = blocks
	  movie.fsk18       = fsk18
	  movie.isMovie     = 1
	  movie.pid = 10000 + TMovie.LastUniqueID  '10000 = base for MOVIES
	  TMovie.LastUniqueID:+1
	  movie.actors 		= actors
	  movie.director    = director
	  movie.country     = country
	  movie.year        = year
	  movie.livehour    = livehour
	  movie.Outcome     = Outcome
      movie.topicality  = movie.ComputeTopicality()
      movie.maxtopicality  = movie.ComputeTopicality()
	  ProgList.AddLast(movie)
	  ProgMovieList.AddLast(movie)
	  Return movie
	End Function
End Type

Type TSeries Extends TProgramme
Global LastUniqueID:Int=0
	Function Create:TSeries(title:String, description:String, actors:String, director:String, country:String, year:Int, livehour:Int, Outcome:Float, review:Float, speed:Float, relPrice:Int, Genre:Int, blocks:Int, fsk18:String, episode:Int=0, id:Int=0)
	  Local serie:TSeries =New TSeries
	  serie.BaseInit(title, description, 0)
	  serie.review      = review
	  serie.speed       = speed
	  serie.relPrice    = relPrice
	  serie.Genre       = Genre
	  serie.blocks      = blocks
	  serie.fsk18       = fsk18
	  serie.isMovie     = 0
	  serie.episodeNumber = episode
	  serie.pid = 20000 + TSeries.LastUniqueID  '20000 = base for SERIES
	  TSeries.LastUniqueID:+1
	  serie.actors 		= actors
	  serie.director    = director
	  serie.country     = country
	  serie.year        = year
	  serie.livehour    = livehour
      serie.topicality  = serie.ComputeTopicality()
      serie.maxtopicality  = serie.ComputeTopicality()
	  ProgList.AddLast(serie)
	  ProgSeriesList.AddLast(serie)
	  Return serie
	End Function

	Method AddEpisode:TSeries(title:String, description:String, actors:String, director:String, country:String, year:Int, livehour:Int, Outcome:Float, review:Float, speed:Float, relPrice:Int, Genre:Int, blocks:Int, fsk18:String, episode:Int=0, id:Int=0)
	  Local localepisode:TSeries =New TSeries
	  localepisode.BaseInit( title, description, 20000 + TSeries.LastUniqueID)
	  localepisode.review      = review
	  localepisode.speed       = speed
	  localepisode.relPrice    = relPrice

	  localepisode.blocks      = blocks
	  localepisode.fsk18       = fsk18
	  localepisode.isMovie     = 0
	  localepisode.episodeNumber = episode
	  localepisode.pid = 20000 + TSeries.LastUniqueID  '20000 = base for SERIES
	  TSeries.LastUniqueID:+1
	  localepisode.actors 		= actors
	  localepisode.director    = director
	  localepisode.country     = country
	  localepisode.year        = year
	  localepisode.livehour    = livehour

		Local serie:TSeries = TSeries(TProgramme.ProgSeriesList.ValueAtIndex(TProgramme.ProgSeriesList.Count() - 1))
        serie.episodecount :+ 1
		'ron 2012 - xml load has episode
	   'localepisode.episodeNumber = serie.episodecount

	   localepisode.Genre = serie.genre

	  serie.episodeList.AddLast(localepisode)
	  ProgList.AddLast(localepisode)
	  Return localepisode
	End Method

	Function GetLast:TSeries()
		Local serie:TSeries
		serie = TSeries(TProgramme.ProgSeriesList.ValueAtIndex(TProgramme.ProgSeriesList.Count() - 1) )
'		serie = TSeries(TProgramme.ProgSeriesList.items[TProgramme.ProgSeriesList.count()-1])
		Return serie
	End Function


End Type


Type TDatabase
	Field file:String
	Field moviescount:Int
	Field totalmoviescount:Int
	Field seriescount:Int
	Field newscount:Int
	Field totalnewscount:Int
	Field contractscount:Int

	Function Create:TDatabase()
		Local Database:TDatabase=New TDatabase
		Database.file				= ""
		Database.moviescount   		= 0
		Database.totalmoviescount	= 0
		Database.seriescount		= 0
		Database.newscount			= 0
		Database.contractscount		= 0
		Return Database
	End Function


	Method Load(filename:String)
		Local title:String
		Local description:String
		Local actors:String
		Local director:String
		Local land:String
		Local year:Int
		Local Genre:Int
		Local duration:Int
		Local fsk18:int
		Local price:Int
		Local review:Int
		Local speed:Int
		Local Outcome:Int
		Local livehour:Int

		Local daystofinish:Int
		Local spotcount:Int
		Local targetgroup:Int
		Local minaudience:Int
		Local profit:Int
		Local penalty:Int

		Local quality:Int


		local xml:TXmlHelper = TXmlHelper.Create(filename)
		local nodeParent:TxmlNode
		local nodeChild:TxmlNode
		local nodeEpisode:TxmlNode
		local listChildren:TList
		local loadError:string = ""



		'---------------------------------------------
		'importing all movies
		nodeParent		= xml.FindRootChild("allmovies")
		loadError		= "Problems loading movies. Check database.xml"
		if nodeParent <> null
			listChildren = nodeParent.getChildren()
			if listChildren = null then throw loadError

			for nodeChild = eachIn listChildren
				If nodeChild.getName() = "movie"
					xml.setNode(nodeChild)
					title       = xml.FindValue("title", "unknown title")
					description = xml.FindValue("description", "23")
					actors      = xml.FindValue("actors", "")
					director    = xml.FindValue("director", "")
					land        = xml.FindValue("country", "UNK")
					year 		= xml.FindValueInt("year", 1900)
					Genre 		= xml.FindValueInt("genre", 0 )
					duration    = xml.FindValueInt("blocks", 2)
					fsk18 		= xml.FindValueInt("xrated", 0)
					price 		= xml.FindValueInt("price", 0)
					review 		= xml.FindValueInt("review", 0)
					speed 		= xml.FindValueInt("speed", 0)
					Outcome 	= xml.FindValueInt("outcome", 0)
					livehour 	= xml.FindValueInt("time", 0)
					If duration < 0 Or duration > 12 Then duration =1
					TMovie.Create(title,description,actors, director,land, year, livehour, Outcome, review, speed, price, Genre, duration, fsk18,Database.totalmoviescount,0)
					'print "film: "+title+ " " + Database.totalmoviescount
					Database.totalmoviescount :+ 1
				EndIf
			Next
		else
			throw loadError
		endif

		'---------------------------------------------
		'importing all series including their episodes
		nodeParent		= xml.FindRootChild("allseries")
		loadError		= "Problems loading series. Check database.xml"
		if nodeParent = null then throw loadError
		listChildren = nodeParent.getChildren()
		if listChildren = null then throw loadError
		for nodeChild = eachIn listChildren
			If nodeChild.getName() = "serie"
				'load series main data
				xml.setNode(nodeChild)
				title       = xml.FindValue("title", "unknown title")
				description = xml.FindValue("description", "23")
				actors      = xml.FindValue("actors", "")
				director    = xml.FindValue("director", "")
				land        = xml.FindValue("country", "UNK")
				year 		= xml.FindValueInt("year", 1900)
				Genre 		= xml.FindValueInt("genre", 0)
				duration    = xml.FindValueInt("blocks", 2)
				fsk18 		= xml.FindValueInt("xrated", 0)
				price 		= xml.FindValueInt("price", 0)
				review 		= xml.FindValueInt("review", 0)
				speed 		= xml.FindValueInt("speed", 0)
				Outcome 	= xml.FindValueInt("outcome", 0)
				livehour 	= xml.FindValueInt("time", 0)
				If duration < 0 Or duration > 12 Then duration =1
				TSeries.Create(title,description,actors, director,land, year, livehour, Outcome, review, speed, price, Genre, duration, Database.totalmoviescount,0)
				Database.seriescount :+ 1

				'load episodes
				local EpisodeNum:int = 0
				local listEpisodes:TList = nodeChild.getChildren()
				if listEpisodes <> null AND listEpisodes.count() > 0
					for nodeEpisode = eachIn listEpisodes
						If nodeEpisode.getName() = "episode"
							xml.setNode(nodeEpisode)
							EpisodeNum	= xml.FindValueInt("number", EpisodeNum+1)
							title      	= xml.FindValue("title", title)
							description = xml.FindValue("description", description)
							actors      = xml.FindValue("actors", actors)
							director    = xml.FindValue("director", director)
							land        = xml.FindValue("country", land)
							year 		= xml.FindValueInt("year", year)
							Genre 		= xml.FindValueInt("genre", Genre)
							duration    = xml.FindValueInt("blocks", duration)
							fsk18 		= xml.FindValueInt("xrated", fsk18)
							price 		= xml.FindValueInt("price", price)
							review 		= xml.FindValueInt("review", review)
							speed 		= xml.FindValueInt("speed", speed)
							Outcome 	= xml.FindValueInt("outcome", Outcome)
							livehour	= xml.FindValueInt("time", livehour)
							'add episode to last added serie
							'print "serie: --- episode:"+title
							TSeries.GetLast().AddEpisode(title,description,actors, director,land, year, livehour, Outcome, review, speed, price, Genre, duration, fsk18, EpisodeNum, Database.totalmoviescount)
						EndIf
					Next
				Endif
			Endif
		Next

		'---------------------------------------------
		'importing all ads
		nodeParent		= xml.FindRootChild("allads")
		loadError		= "Problems loading ads. Check database.xml"
		if nodeParent = null then throw loadError

		listChildren = nodeParent.getChildren()
		if listChildren = null then throw loadError
		for nodeChild = eachIn listChildren
			If nodeChild.getName() = "ad"
				xml.setNode(nodeChild)
				title       = xml.FindValue("title", "unknown title")
				description = xml.FindValue("description", "")
				targetgroup = xml.FindValueInt("targetgroup", 0)
				spotcount	= xml.FindValueInt("repetitions", 1)
				minaudience	= xml.FindValueInt("minaudience", 0)
				profit	    = xml.FindValueInt("profit", 0)
				penalty		= xml.FindValueInt("penalty", 0)
				daystofinish= xml.FindValueInt("time", 1)

				TContract.Create(title, description, daystofinish, spotcount, targetgroup, minaudience, profit, penalty, Database.contractscount)
				'print "contract: "+title+ " " + Database.contractscount
				Database.contractscount :+ 1
			EndIf
		Next


		'---------------------------------------------
		'importing all news including their chains
		nodeParent		= xml.FindRootChild("allnews")
		loadError		= "Problems loading news. Check database.xml"
		if nodeParent = null then throw loadError
		listChildren = nodeParent.getChildren()
		if listChildren = null then throw loadError
		for nodeChild = eachIn listChildren
			If nodeChild.getName() = "news"
				'load series main data
				xml.setNode(nodeChild)
				title       = xml.FindValue("title", "unknown newstitle")
				description	= xml.FindValue("description", "")
				genre		= xml.FindValueInt("genre", 0)
				quality		= xml.FindValueInt("topicality", 0)
				price		= xml.FindValueInt("price", 0)
				TNews.Create(title, description, Genre, Database.totalnewscount,quality, price, 0)

				'load episodes
				local EpisodeNum:int = 0
				local listEpisodes:TList = nodeChild.getChildren()
				if listEpisodes <> null AND listEpisodes.count() > 0
					for nodeEpisode = eachIn listEpisodes
						If nodeEpisode.getName() = "episode"
							xml.setNode(nodeEpisode)
							EpisodeNum		= xml.FindValueInt("number", EpisodeNum+1)
							title			= xml.FindValue("title", "unknown Newstitle")
							description		= xml.FindValue("description", "")
							genre			= xml.FindValueInt("genre", genre)
							quality			= xml.FindValueInt("topicality", quality)
							price			= xml.FindValueInt("price", price)
							TNews.GetLast().AddEpisode(title,description, Genre, EpisodeNum,quality, price, Database.totalnewscount)
							Database.totalnewscount :+1
						EndIf
					Next
					Database.newscount :+ 1
					Database.totalnewscount :+1
				EndIf
			Endif
		Next

		print("found " + Database.seriescount+ " series")
		print("found " + Database.totalmoviescount+ " movies")
		print("found " + Database.contractscount + " advertisements")
		print("found " + Database.newscount+ " newsstreams with " + Database.totalnewscount + " news")
	End Method
End Type





Type TAdBlock Extends TBlockGraphical
	Field title:String 							{saveload = "normal"}
	field text:string				= ""
	Field State:Int 				= 0			{saveload = "normal"}
    Field timeset:Int 				=-1			{saveload = "normal"}
    Field Height:Int							{saveload = "normal"}
    Field width:Int								{saveload = "normal"}
    Field botched:Int				= 0			{saveload = "normal"}   		 'contract-audience reached or not
    Field blocks:Int				= 1			{saveload = "normal"}
    Field senddate:Int				=-1			{saveload = "normal"} 			 'which day this ad is planned to be send?
    Field sendtime:Int				=-1			{saveload = "normal"}			 'which time this ad is planned to be send?
    Field contract:TContract
    Field uniqueID:Int				= 0			{saveload = "normal"}
	Field Link:TLink
    Global LastUniqueID:Int			= 0
    Global DragAndDropList:TList
    Global List:TList

    Global spriteBaseName:string = "pp_adblock1"

  Function LoadAll(loadfile:TStream)
    TAdBlock.List.Clear()
	Print "cleared adblocklist:"+TAdBlock.List.Count()
    Local BeginPos:Int = Stream_SeekString("<ADB/>",loadfile)+1
    Local EndPos:Int = Stream_SeekString("</ADB>",loadfile)  -6
    Local strlen:Int = 0
    loadfile.Seek(BeginPos)

	TAdBlock.lastUniqueID:Int        = ReadInt(loadfile)
    TAdBlock.AdditionallyDragged:Int = ReadInt(loadfile)
	Repeat
      Local AdBlock:TAdBlock= New TAdBlock
	  strlen = ReadInt(loadfile); AdBlock.title = ReadString(loadfile, strlen)
	  AdBlock.state    = ReadInt(loadfile)
	  AdBlock.dragable = ReadInt(loadfile)
	  AdBlock.dragged = ReadInt(loadfile)
	  AdBlock.StartPos.Load(Null)
	  AdBlock.timeset   = ReadInt(loadfile)
	  AdBlock.height   = ReadInt(loadfile)
	  AdBlock.width   = ReadInt(loadfile)
	  AdBlock.botched = ReadInt(loadfile)
	  AdBlock.blocks   = ReadInt(loadfile)
	  AdBlock.senddate = ReadInt(loadfile)
	  AdBlock.sendtime = ReadInt(loadfile)
	  AdBlock.owner    = ReadInt(loadfile)
	  Local ContractID:Int = ReadInt(loadfile)
      If ContractID >= 0
	    Local contract:TContract = New TContract
		contract = TContract.Load(Null) 'loadfile)
        AdBlock.contract = New TContract
 	    AdBlock.contract = Player[AdBlock.owner].ProgrammePlan.CloneContract(contract)
 	    AdBlock.contract.owner = AdBlock.owner
        AdBlock.contract.senddate = contract.senddate
        AdBlock.contract.sendtime = contract.sendtime
 	    AdBlock.contract.spotnumber = Adblock.GetPreviousContractCount()
	  EndIf
		AdBlock.Pos.Load(Null)
	  AdBlock.uniqueID = ReadInt(loadfile)
	  AdBlock.Link = TAdBlock.List.AddLast(AdBlock)
	  ReadString(loadfile,5) 'finishing string (eg. "|PRB|")
	  Player[AdBlock.owner].ProgrammePlan.AddContract(AdBlock.contract)
	Until loadfile.Pos() >= EndPos
	Print "loaded adblocklist"
  End Function

	Function SaveAll()
		LoadSaveFile.xmlBeginNode("ALLADBLOCKS")
			LoadSaveFile.xmlWrite("LASTUNIQUEID", 			TAdBlock.LastUniqueID)
			LoadSaveFile.xmlWrite("ADDITIONALLYDRAGGED", 	TAdBlock.AdditionallyDragged)
			For Local AdBlock:TAdBlock= EachIn TAdBlock.List
				If AdBlock <> Null Then AdBlock.Save()
			Next
		LoadSaveFile.xmlCloseNode()
	End Function

	Method Save()
		LoadSaveFile.xmlBeginNode("ADBLOCK")
			Local typ:TTypeId = TTypeId.ForObject(Self)
			For Local t:TField = EachIn typ.EnumFields()
				If t.MetaData("saveload") = "normal"
					LoadSaveFile.xmlWrite(Upper(t.name()), String(t.Get(Self)))
				EndIf
			Next
			If Self.contract <> Null
				LoadSaveFile.xmlWrite("CONTRACTID", 	Self.contract.id)
				Self.contract.Save()
			Else
				LoadSaveFile.xmlWrite("CONTRACTID", 	"-1")
			EndIf
		LoadSavefile.xmlCloseNode()
	End Method

	Function Create:TAdBlock(text:String = "unknown", x:Int = 0, y:Int = 0, owner:Int = 0, contractpos:Int = -1)
	  Local AdBlock:TAdBlock=New TAdBlock
	  AdBlock.Pos 		= TPosition.Create(x, y)
	  AdBlock.StartPos	= TPosition.Create(x, y)
 	  Adblock.owner = owner
 	  AdBlock.blocks = 1
 	  AdBlock.State = 0
 	  Adblock.uniqueID = owner*30000 + TAdBlock.LastUniqueID
 	  TAdBlock.LastUniqueID :+1

 	  'hier noch als variablen uebernehmen
 	  AdBlock.dragable = 1
 	  AdBlock.width = Assets.GetSprite("pp_adblock1").w
 	  AdBlock.Height = Assets.GetSprite("pp_adblock1").h
 	  AdBlock.senddate = Game.day
 	  AdBlock.sendtime = AdBlock.GetTimeOfBlock()

      Local _contract:TContract
      If contractpos <= -1
   	    _contract = Player[owner].ProgrammeCollection.GetLocalRandomContract()
 	  Else
 		SortList(Player[owner].ProgrammeCollection.ContractList)
 	    _contract = TContract(Player[owner].ProgrammeCollection.ContractList.ValueAtIndex(contractPos-1))
 	  EndIf
  	  AdBlock.contract = New TContract
 	  AdBlock.contract = Player[owner].ProgrammePlan.CloneContract(_contract)
 	  AdBlock.contract.owner = owner
 	  AdBlock.contract.spotnumber = Player[owner].ProgrammePlan.GetPreviousContractCount(AdBlock.contract)
  	  AdBlock.contract.senddate = Game.day
 	  AdBlock.contract.sendtime = Int(Floor((Adblock.StartPos.y - 17) / 30))


 	  AdBlock.title = Adblock.contract.title
 	  If Not List Then List = CreateList()
 	  Adblock.Link = List.AddLast(AdBlock)
 	  'SortList List
 	  SortList(List)
	  Player[owner].ProgrammePlan.AddContract(AdBlock.contract)
 	  Return AdBlock
	End Function

	Function CreateDragged:TAdBlock(contract:TContract, owner:Int=-1)
	  Local playerID:Int =0
	  If owner < 0 Then playerID = game.playerID Else playerID = owner
	  Local AdBlock:TAdBlock=New TAdBlock
 	  AdBlock.Pos 			= TPosition.Create(MouseX(), MouseY())
 	  AdBlock.StartPos		= TPosition.Create(0, 0)
 	  AdBlock.owner 		= playerID
 	  AdBlock.State 		= 0
 	  Adblock.uniqueID 		= playerID*30000 + TAdBlock.LastUniqueID
 	  TAdBlock.LastUniqueID :+1
 	  AdBlock.dragable 		= 1
 	  AdBlock.width 		= Assets.GetSprite("pp_adblock1").w
 	  AdBlock.Height		= Assets.GetSprite("pp_adblock1").h
 	  AdBlock.senddate 		= Game.daytoplan
      AdBlock.sendtime 		= 100

      AdBlock.contract = New TContract
 	  AdBlock.contract				= Player[playerID].ProgrammePlan.CloneContract(contract)
 	  AdBlock.contract.owner		= playerID
 	  AdBlock.contract.spotnumber 	= Adblock.GetPreviousContractCount()
  	  Adblock.dragged 				= 1
 	  AdBlock.title 				= Adblock.contract.title
 	  If Not List Then List = CreateList()
	  Adblock.Link 					= List.AddLast(AdBlock)
	  SortList(TAdBlock.List)
 	  Return Adblock
	End Function

	Function GetActualAdBlock:TAdBlock(playerID:Int = -1, time:Int = -1, day:Int = -1)
		If playerID = -1 Then playerID = Game.playerID
		If time = -1 Then time = Game.GetActualHour()
		If day = -1 Then day = Game.day

		For Local Obj:TAdBlock = EachIn TAdBlock.list
			If Obj.owner = playerID
				If (Obj.sendtime) = time And Obj.senddate = day Then Return Obj
			EndIf
  		Next
		Return Null
  	End Function

	Method SetDragable(_dragable:Int = 1)
		dragable = _dragable
	End Method

    Method Compare:Int(otherObject:Object)
       Local s:TAdBlock = TAdBlock(otherObject)
       If Not s Then Return 1                  ' Objekt nicht gefunden, an das Ende der Liste setzen
        Return (10000*dragged + (sendtime + 25*senddate))-(10000*s.dragged + (s.sendtime + 25*s.senddate))
    End Method


	Method GetBlockX:Int(time:Int)
		If time < 12 Then Return 67 + Assets.GetSprite("pp_programmeblock1").w
		Return 394 + Assets.GetSprite("pp_programmeblock1").w
	End Method

	Method GetBlockY:Int(time:Int)
		If time < 12 Then Return time * 30 + 17
		Return (time - 12) * 30 + 17
	End Method

    Method GetTimeOfBlock:Int(_x:Int = 1000, _y:Int = 1000)
		If StartPos.x = 589
    	  Return 12+(Int(Floor(StartPos.y - 17) / 30))
		Else If StartPos.x = 262
    	  Return 1*(Int(Floor(StartPos.y - 17) / 30))
    	EndIf
    	Return -1
    End Method

    'draw the Adblock inclusive text
    'zeichnet den Programmblock inklusive Text
    Method Draw()
		'Draw dragged Adblockgraphic
		If dragged = 1 Or senddate = Game.daytoplan 'out of gameplanner
			State = 1
			If Game.day > Game.daytoplan Then State = 4
			If Game.day < Game.daytoplan Then State = 0
			If Game.day = Game.daytoplan
				If GetTimeOfBlock() > (Int(Floor((Game.minutesOfDayGone-55) / 60))) Then State = 0  'normal
				If GetTimeOfBlock() = (Int(Floor((Game.minutesOfDayGone-55) / 60))) Then State = 2  'running
				If GetTimeOfBlock() < (Int(Floor((Game.minutesOfDayGone) / 60)))    Then State = 1  'runned
				If GetTimeOfBlock() < 0      									    Then State = 0  'normal
			EndIf

			If State = 0 Then SetColor 255,255,255;dragable=1  'normal
			If State = 1 Then SetColor 200,255,200;dragable=0  'runned
			If State = 2 Then SetColor 250,230,120;dragable=0  'running
			If State = 4 Then SetColor 255,255,255;dragable=0  'old day

			local variant:string = ""
			If dragged = 1 And State = 0
				If TAdBlock.AdditionallyDragged >0 Then SetAlpha 1- (1/TAdBlock.AdditionallyDragged * 0.25)
				variant = "_dragged"
			EndIf
			Assets.GetSprite("pp_adblock1"+variant).Draw(Pos.x, Pos.y)

			'draw graphic

			SetColor 0,0,0
			FontManager.baseFontBold.DrawBlock(title, pos.x + 3, pos.y+3, self.width, 18, 0, 0, 0, 0, True)
			SetColor 80,80,80
			self.text = (contract.spotnumber)+"/"+contract.spotcount
			If State = 1 And contract.spotnumber = contract.spotcount
				self.text = "- OK -"
			ElseIf contract.botched=1
				self.text = "------"
				'contract.spotnumber = -1
			EndIf
			FontManager.baseFont.Draw(self.text ,Pos.x+5,Pos.y+18)
			SetColor 255,255,255 'eigentlich alte Farbe wiederherstellen
			SetAlpha 1.0
		EndIf 'same day or dragged
    End Method

	Function DrawAll(origowner:Int)
      'SortList TAdBlock.List
	  SortList(TAdBlock.List)
      For Local AdBlock:TAdBlock = EachIn TAdBlock.List
        If origowner = Adblock.owner ' or Adblock.owner = Game.playerID
     	  AdBlock.Draw()
        EndIf
      Next
	End Function

	Function UpdateAll(origowner:Int)
      Local gfxListenabled:Byte = 0
      Local havetosort:Byte = 0
      Local number:Int = 0
      If PPprogrammeList.enabled <> 0 Or PPcontractList.enabled <> 0 Then gfxListenabled = 1

      'SortList TAdBlock.List
	  SortList(TAdBlock.List)
      For Local AdBlock:TAdBlock = EachIn TAdBlock.List
      If Adblock.owner = Game.playerID And origowner = game.playerID
        number :+ 1
        If AdBlock.dragged = 1 Then AdBlock.timeset = -1; AdBlock.contract.senddate = Game.daytoplan
        If PPprogrammeList.enabled=0 And MOUSEMANAGER.IsHit(2) And AdBlock.dragged = 1
'          Game.IsMouseRightHit = 0
          For Local i:Byte = 0 To AdBlock.blocks
		    TDragAndDrop.FindAndSetDragAndDropTargetUnUsed(AdBlock.DragAndDropList, AdBlock.StartPos.x, AdBlock.StartPos.y+i*30)
          Next
          ReverseList TAdBlock.List
          Adblock.RemoveBlock()
          Adblock.Link.Remove()
		  havetosort = 1
          ReverseList TAdBlock.List
          AdBlock.GetPreviousContractCount()
          MOUSEMANAGER.resetKey(2)
        EndIf
		If Adblock.dragged And Adblock.StartPos.x>0 And Adblock.StartPos.y >0
		 If Adblock.GetTimeOfBlock() < game.GetActualHour() Or (Adblock.GetTimeOfBlock() = game.GetActualHour() And game.GetActualMinute() >= 55)
			Adblock.dragged = False
 		 EndIf
		EndIf

        If gfxListenabled=0 And MOUSEMANAGER.IsHit(1)
	    	If AdBlock.dragged = 0 And AdBlock.dragable = 1 And Adblock.State = 0
    	        If Adblock.senddate = game.daytoplan
					If functions.IsIn(MouseX(), MouseY(), AdBlock.pos.x, Adblock.pos.y, AdBlock.width, AdBlock.height-1)
						AdBlock.dragged = 1
						For Local OtherlocObject:TAdBlock = EachIn TAdBlock.List
							If OtherLocObject.dragged And OtherLocObject <> Adblock And OtherLocObject.owner = Game.playerID
								TPosition.SwitchPos(AdBlock.StartPos, OtherlocObject.StartPos)
  								OtherLocObject.dragged = 1
								If OtherLocObject.GetTimeOfBlock() < game.GetActualHour() And game.GetActualMinute() >= 55
									OtherLocObject.dragged = 0
								EndIf
							End If
						Next
						Adblock.RemoveBlock() 'just removes the contract from the plan, the adblock still exists
						AdBlock.GetPreviousContractCount()
					EndIf
				EndIf
			Else
            Local DoNotDrag:Int = 0
            If PPprogrammeList.enabled=0 And MOUSEMANAGER.IsHit(1)  And Adblock.State = 0
'			  Print ("X:"+Adblock.x+ " Y:"+Adblock.y+" time:"+Adblock.GetTimeOfBlock(Adblock.x,Adblock.y))' > game.GetActualHour())
              AdBlock.dragged = 0
              For Local DragAndDrop:TDragAndDrop = EachIn TAdBlock.DragAndDropList
                If DragAndDrop.Drop(MouseX(),MouseY(),"adblock") = 1
                  For Local OtherAdBlock:TAdBlock = EachIn TAdBlock.List
                   If OtherAdBlock.owner = Game.playerID Then
                   'is there a Adblock positioned at the desired place?
                      If MOUSEMANAGER.IsHit(1) And OtherAdBlock.dragable = 1 And OtherAdBlock.pos.x = DragAndDrop.rectx
                        If OtherAdblock.senddate = game.daytoplan
                         If OtherAdBlock.pos.y = DragAndDrop.recty
                           If OtherAdBlock.State = 0
                             OtherAdBlock.dragged = 1
           	    	         otherAdblock.RemoveBlock()
          					 havetosort = 1
                           Else
                             DoNotDrag = 1
                           EndIf
             	         EndIf
             	        EndIf
                      EndIf
                    If havetosort
       				  OtherAdBlock.GetPreviousContractCount()
  	          		  AdBlock.GetPreviousContractCount()
                      Exit
                    EndIf
                   EndIf
                  Next
                  If DoNotDrag <> 1
					 Local oldx:Int = AdBlock.StartPos.x
					 Local oldy:Int = Adblock.StartPos.y
               		 AdBlock.startPos.SetXY(DragAndDrop.rectx, DragAndDrop.recty)
					 If Adblock.GetTimeOfBlock() < Game.GetActualHour() Or (Adblock.GetTimeOfBlock() = Game.GetActualHour() And Game.GetActualMinute() >= 55)
						adblock.dragged = True
						If AdBlock.startPos.x = oldx And Adblock.startPos.y = oldy Then Adblock.dragged = False
						AdBlock.StartPos.setXY(oldx, oldy)
						MOUSEMANAGER.resetKey(1)
					 Else
						AdBlock.StartPos.setXY(oldx, oldy)
						Adblock.Pos.SetXY(DragAndDrop.rectx, DragAndDrop.recty)
			    		TDragAndDrop.FindAndSetDragAndDropTargetUnUsed(AdBlock.DragAndDropList, AdBlock.StartPos.x, AdBlock.StartPos.y)
		    			TDragAndDrop.FindAndSetDragAndDropTargetUsed(AdBlock.DragAndDropList, AdBlock.pos.x, AdBlock.pos.y)
						AdBlock.StartPos.SetPos(AdBlock.pos)
                     EndIf
					Exit 'exit loop-each-dragndrop, we've already found the right position
				  EndIf
                EndIf
              Next
				If AdBlock.IsAtStartPos()
					AdBlock.Pos.SetPos(AdBlock.StartPos)
	      		    AdBlock.dragged    			= 0
    	            AdBlock.contract.sendtime	= Adblock.GetTimeOfBlock()
        	        AdBlock.contract.senddate	= Game.daytoplan
            	    AdBlock.sendtime			= Adblock.GetTimeOfBlock()
                	AdBlock.senddate			= Game.daytoplan
	   	            Adblock.AddBlock()
					SortList(TAdBlock.List)
    		        AdBlock.GetPreviousContractCount()
				EndIf
            EndIf
          EndIf
         EndIf

        If AdBlock.dragged = 1
  		  	Adblock.State = 0
			TAdBlock.AdditionallyDragged = TAdBlock.AdditionallyDragged +1
			AdBlock.Pos.SetXY(MouseX() - AdBlock.width  /2 - TAdBlock.AdditionallyDragged *5,..
							  MouseY() - AdBlock.height /2 - TAdBlock.AdditionallyDragged *5)
        EndIf
        If AdBlock.dragged = 0
          If Adblock.StartPos.x = 0 And Adblock.StartPos.y = 0
          	AdBlock.dragged = 1
          	TAdBlock.AdditionallyDragged = TAdBlock.AdditionallyDragged +1
          Else
				AdBlock.Pos.SetPos(AdBlock.StartPos)
          EndIf
        EndIf
      EndIf
      If origowner = Adblock.owner ' or Adblock.owner = Game.playerID
     	'AdBlock.Draw()
      EndIf
      Next
        TAdBlock.AdditionallyDragged = 0
    End Function

  Method RemoveOverheadAdblocks:Int()
    sendtime = GetTimeOfBlock()
  	Local count:Int = 1
  	If Not List Then List = CreateList()
  	For Local AdBlock:TAdBlock= EachIn List
  	  If Adblock.owner = contract.owner And Adblock.contract.title = contract.title And adblock.contract.botched <> 1
  	    AdBlock.contract.spotnumber = count
  	    If count > contract.spotcount And Game.day <= Adblock.senddate
  	      'DebugLog "removing overheadadblock"
  	      'TAdBlock.List.Remove(Adblock)
		  Adblock.Link.Remove()
  	    Else
  	      count :+ 1
  	    EndIf
  	  EndIf
  	Next
  '	contract.spotnumber = count-1
  	Return count
  End Method

  'removes Adblocks which are supposed to be deleted for its contract being obsolete (expired)
  Function RemoveAdblocks:Int(Contract:TContract, BeginDay:Int=0)
  	If Not List Then List = CreateList()
  	For Local AdBlock:TAdBlock= EachIn List
  	  If Adblock.owner = contract.owner And Adblock.contract.title = contract.title And..
	     (adblock.contract.daysigned + adblock.contract.daystofinish < BeginDay)
        'TAdBlock.List.Remove(Adblock)
		Adblock.Link.Remove()
  	  EndIf
  	Next
  End Function

   Method ShowSheet:Int(x:Int,y:Int)
    contract.GetMinAudienceNumber(contract.minaudience)
 	gfx_datasheets_contract.render(x,y)
	'DrawImage gfx_datasheets_contract,x,y

	FontManager.baseFont.DrawBlock(contract.title 	       , x+10 , y+8  , 270, 70)  'prints title on moviesheet
 	FontManager.baseFont.DrawBlock(contract.description      , x+10 , y+30 , 270, 70) 'prints programmedescription on moviesheet
 	FontManager.baseFont.DrawBlock(Localization.GetString("AD_PROFIT")+": "       , x+10 , y+91 , 130, 16)
 	FontManager.baseFont.DrawBlock(functions.convertValue(String(contract.calculatedProfit), 2, 0) , x+10 , y+91 , 130, 16,2)
 	FontManager.baseFont.DrawBlock(Localization.GetString("AD_TOSEND")+": "    , x+150, y+91 , 127, 16)
 	FontManager.baseFont.DrawBlock((contract.spotcount - GetSuccessfullSentContractCount())+"/"+contract.spotcount , x+150, y+91 , 127, 16,2)
 	FontManager.baseFont.DrawBlock(Localization.GetString("AD_PENALTY")+": "       , x+10 , y+114, 130, 16)
 	FontManager.baseFont.DrawBlock(functions.convertValue(String(contract.calculatedPenalty), 2, 0), x+10 , y+114, 130, 16,2)
 	FontManager.baseFont.DrawBlock(Localization.GetString("AD_MIN_AUDIENCE")+": "    , x+150, y+114, 127, 16)
 	FontManager.baseFont.DrawBlock(functions.convertValue(String(contract.calculatedminaudience), 2, 0), x+150, y+114, 127, 16,2)
 	FontManager.baseFont.DrawBlock(Localization.GetString("AD_TARGETGROUP")+": "+TContract.GetTargetgroupName(contract.targetgroup)   , x+10 , y+137 , 270, 16)
 	If (contract.daystofinish-(Game.day - contract.daysigned)) = 0
 	  FontManager.baseFont.DrawBlock(Localization.GetString("AD_TIME")+": "+Localization.GetString("AD_TILL_TODAY") , x+86 , y+160 , 126, 16)
 	Else If (contract.daystofinish-(Game.day - contract.daysigned)) = 1
 	  FontManager.baseFont.DrawBlock(Localization.GetString("AD_TIME")+": "+Localization.GetString("AD_TILL_TOMORROW") , x+86 , y+160 , 126, 16)
 	Else
 	  FontManager.baseFont.DrawBlock(Localization.GetString("AD_TIME")+": "+Replace(Localization.GetString("AD_STILL_X_DAYS"),"%1", (contract.daystofinish-(Game.day - contract.daysigned))), x+86 , y+160 , 126, 16)
 	EndIf
 End Method

   Method GetPreviousContractCount:Int()
    sendtime = GetTimeOfBlock()
  	Local count:Int = 1
  	If Not List Then List = CreateList()
  	For Local AdBlock:TAdBlock= EachIn List
  	  If Adblock.owner = contract.owner And Adblock.contract.title = contract.title And adblock.contract.botched <> 1
  	    AdBlock.contract.spotnumber = count
  	    count :+ 1
  	  '  If count > contract.spotcount and Game.day > Game.daytoplan Then count = 1
  	  EndIf
  	Next
  '	contract.spotnumber = count-1
  	Return count
  End Method

   Method GetSuccessfullSentContractCount:Int()
    sendtime = GetTimeOfBlock()
  	Local count:Int = 0
  	If Not List Then List = CreateList()
  	For Local AdBlock:TAdBlock= EachIn List
  	  If Adblock.owner = contract.owner And Adblock.contract.title = contract.title And adblock.contract.botched = 3
  	    count :+ 1
  	  EndIf
  	Next
  	Return count
  End Method
    'remove from programmeplan
    Method RemoveBlock()
   	  Player[Game.playerID].ProgrammePlan.RemoveContract(Self.contract)
      If game.networkgame Then Network.SendPlanAdChange(game.playerID, Self, 0)
    End Method

    Method AddBlock()
      'Print "LOCAL: added adblock:"+Self.contract.title
'      Player[game.playerID].ProgrammePlan.RefreshProgrammePlan(game.playerID, Self.Programme.senddate)
      Player[Game.playerID].ProgrammePlan.AddContract(Self.contract)
      If game.networkgame Then Network.SendPlanAdChange(game.playerID, Self, 1)
    End Method

    Function GetBlockByContract:TAdBlock(contract:TContract)
	 For Local _AdBlock:TAdBlock = EachIn TAdBlock.List
		If contract.daysigned = _Adblock.contract.daysigned..
		   And contract.title = _Adblock.contract.title..
		   And contract.owner = _Adblock.contract.owner
		  Return _Adblock
		EndIf
	 Next
    End Function

	Function GetBlock:TAdBlock(id:Int)
	 For Local _AdBlock:TAdBlock = EachIn TAdBlock.List
	 	If _Adblock.uniqueID = id Then Return _Adblock
	 Next
		return null
	End Function
End Type

Type TProgrammeBlock Extends TBlockGraphical
    Field pbid:Int = MilliSecs() {saveload = "normal"}
    Field id:Int = -1 {saveload = "normal"}
	Field title:String {saveload = "normal"}
	Field Genre:String {saveload = "normal"}
	Field State:Int = 0 {saveload = "normal"}
    Field timeset:Int = -1 {saveload = "normal"}
    Field blocks:Int = 1 {saveload = "normal"}
	Field blocktime:Int[]
    Field image:TGW_Sprites
    Field image_dragged:TGW_Sprites
    Field Programme:TProgramme
    Field ParentProgramme:TProgramme
    Field uniqueID:Int = 0 {saveload = "normal"}
	Field Link:TLink
    Global LastUniqueID:Int =0
    Global DragAndDropList:TList
    Global List:TList
    Global AdditionallyDragged:Int =0

  Function LoadAll(loadfile:TStream)
    TProgrammeBlock.List.Clear()
	Print "cleared programmeblocklist:"+TProgrammeBlock.List.Count()
    Local BeginPos:Int = Stream_SeekString("<PRB/>",loadfile)+1
    Local EndPos:Int = Stream_SeekString("</PRB>",loadfile)  -6
    Local strlen:Int = 0
    loadfile.Seek(BeginPos)

	TProgrammeBlock.lastUniqueID:Int        = ReadInt(loadfile)
    TProgrammeBlock.AdditionallyDragged:Int = ReadInt(loadfile)
'	Local FinishString:String = ""
	Repeat
      Local ProgrammeBlock:TProgrammeBlock = New TProgrammeBlock
 	  ProgrammeBlock.image = Assets.GetSprite("pp_programmeblock1")
 	  ProgrammeBlock.image_dragged = Assets.GetSprite("pp_programmeblock1_dragged")
	  ProgrammeBlock.pbid = ReadInt(loadfile)
	  ProgrammeBlock.id   = ReadInt(loadfile)
	  strlen = ReadInt(loadfile); ProgrammeBlock.title = ReadString(loadfile, strlen)
	  strlen = ReadInt(loadfile); ProgrammeBlock.genre = ReadString(loadfile, strlen)
	  ProgrammeBlock.state    = ReadInt(loadfile)
	  ProgrammeBlock.dragable = ReadInt(loadfile)
	  ProgrammeBlock.dragged = ReadInt(loadfile)
	  ProgrammeBlock.StartPos.Load(Null)
	  ProgrammeBlock.timeset = ReadInt(loadfile)
	  ProgrammeBlock.height = ReadInt(loadfile)
	  ProgrammeBlock.width = ReadInt(loadfile)
	  ProgrammeBlock.blocks   = ReadInt(loadfile)
	  ProgrammeBlock.Pos.Load(Null)
	  Local progID:Int = ReadInt(loadfile)
      Local ProgSendDate:Int = ReadInt(loadfile)
      Local ProgSendTime:Int = ReadInt(loadfile)
	  Local ParentprogID:Int = ReadInt(loadfile)
      Local ParentProgSendDate:Int = ReadInt(loadfile)
      Local ParentProgSendTime:Int = ReadInt(loadfile)
	  ProgrammeBlock.owner    = ReadInt(loadfile)
      If ProgID >= 0
        ProgrammeBlock.Programme 		  = Player[ProgrammeBlock.owner].ProgrammePlan.CloneProgramme(Tprogramme.GetProgramme(ProgID))
        ProgrammeBlock.Programme.senddate = ProgSendDate
        ProgrammeBlock.Programme.sendTime = ProgSendTime
	  EndIf
      If ParentProgID >= 0
        ProgrammeBlock.ParentProgramme 		    = Player[ProgrammeBlock.owner].ProgrammePlan.CloneProgramme(Tprogramme.GetProgramme(ParentProgID))
        ProgrammeBlock.ParentProgramme.senddate = ParentProgSendDate
        ProgrammeBlock.ParentProgramme.sendTime = ParentProgSendTime
	  EndIf
	  ProgrammeBlock.uniqueID = ReadInt(loadfile)
	  ProgrammeBlock.Link = TProgrammeBlock.List.AddLast(ProgrammeBlock)
	  ReadString(loadfile, 5)  'finishing string (eg. "|PRB|")
	  Player[ProgrammeBlock.owner].ProgrammePlan.AddProgramme(ProgrammeBlock.Programme, 1)
	Until loadfile.Pos() >= EndPos 'Or FinishString <> "|PRB|"
	Print "loaded programmeblocklist"
  End Function

	Function SaveAll()
		LoadSaveFile.xmlBeginNode("ALLPROGRAMMEBLOCKS")
			LoadSaveFile.xmlWrite("LASTUNIQUEID",		TProgrammeBlock.LastUniqueID)
			LoadSaveFile.xmlWrite("ADDITIONALLYDRAGGED",TProgrammeBlock.AdditionallyDragged)
		    For Local ProgrammeBlock:TProgrammeBlock= EachIn TProgrammeBlock.List
				If ProgrammeBlock <> Null Then ProgrammeBlock.Save()
			Next
		LoadSaveFile.xmlCloseNode()
	End Function

	Method Save()
		LoadSaveFile.xmlBeginNode("PROGRAMMEBLOCK")
			Local typ:TTypeId = TTypeId.ForObject(Self)
			For Local t:TField = EachIn typ.EnumFields()
				If t.MetaData("saveload") = "normal" Or t.MetaData("saveload") = "normalExt"
					LoadSaveFile.xmlWrite(Upper(t.name()), String(t.Get(Self)))
				EndIf
			Next
			If Self.Programme <> Null
				LoadSaveFile.xmlWrite("PROGRAMMEID", Self.Programme.pid)
				LoadSavefile.xmlWrite("PROGRAMMESENDDATE",	Self.Programme.senddate)
				LoadSavefile.xmlWrite("PROGRAMMESENDTIME",	Self.Programme.sendtime)
			Else
				LoadSavefile.xmlWrite("PROGRAMMEID",		"-1")
				LoadSavefile.xmlWrite("PROGRAMMESENDDATE",	"-1")
				LoadSavefile.xmlWrite("PROGRAMMESENDTIME",	"-1")
			EndIf
			If Self.ParentProgramme <> Null
				LoadSaveFile.xmlWrite("PARENTPROGRAMMEID", Self.ParentProgramme.pid)
				LoadSavefile.xmlWrite("PARENTPROGRAMMESENDDATE",	Self.ParentProgramme.senddate)
				LoadSavefile.xmlWrite("PARENTPROGRAMMESENDTIME",	Self.ParentProgramme.sendtime)
			Else
				LoadSavefile.xmlWrite("PARENTPROGRAMMEID",			"-1")
				LoadSaveFile.xmlWrite("PARENTPROGRAMMESENDDATE", "-1")
				LoadSavefile.xmlWrite("PARENTPROGRAMMESENDTIME",	"-1")
			EndIf
	 	LoadSaveFile.xmlCloseNode()
	End Method

	Method SetStartConfig(x:Float, y:Float, owner:Int=0, state:Int=0)
 	  Self.image 		= Assets.GetSprite("pp_programmeblock1")
 	  Self.image_dragged= Assets.GetSprite("pp_programmeblock1_dragged")
	  Self.Pos			= TPosition.Create(x, y)
	  Self.StartPos		= TPosition.Create(x, y)
 	  Self.owner 		= owner
 	  Self.uniqueID 	= owner*10000 + TProgrammeBlock.LastUniqueID
 	  Self.State 		= state
 	  Self.pbid 		= MilliSecs()
	  Self.id 			= MilliSecs()
 	  Self.dragable 	= 1
 	  Self.width 		= Self.image.w
 	  Self.Height 		= Self.image.h
	End Method

	Function Create:TProgrammeBlock(text:String="unknown", x:Int=0, y:Int=0, serie:Int=0, owner:Int=0, programmepos:Int=-1)
		Local ProgrammeBlock:TProgrammeBlock=New TProgrammeBlock
 	  TProgrammeBlock.LastUniqueID :+1
 	  If x = 67  ProgrammeBlock.timeset = (y - 17) / 30
 	  If x = 394 ProgrammeBlock.timeset = 12+ (y - 17) / 30
 	  ProgrammeBlock.SetStartConfig(x,y,owner, Rnd(0,3))
      Local movie:TProgramme
      If Programmepos <= -1
 	    If serie = 0
 	      movie = Player[Game.playerID].ProgrammeCollection.GetLocalRandomMovie()
 	    Else
 	      movie = Player[Game.playerID].ProgrammeCollection.GetLocalRandomSerie()
 	    EndIf
 	  Else
 	    'SortList(Player[owner].ProgrammeCollection.MovieList)
 	    SortList(Player[owner].ProgrammeCollection.MovieList)
 	    movie = TProgramme(Player[owner].ProgrammeCollection.MovieList.ValueAtIndex(programmepos))
 	  EndIf

 	  Local Genre:String
 	  programmeblock.id = movie.pid


 	  ProgrammeBlock.Programme = New TProgramme
 	  ProgrammeBlock.Programme 			= Player[owner].ProgrammePlan.CloneProgramme(movie)
 	  ProgrammeBlock.Programme.senddate = Game.day
 	  ProgrammeBlock.Programme.sendtime = Int(Floor((ProgrammeBlock.StartPos.y - 17) / 30))

      Genre = TProgramme.GetGenre(movie.Genre)
 	  If movie.isMovie = 0 Then Genre = "Serie: "+Genre
 	  Local title :String = movie.title

		local maxWidth:int = ProgrammeBlock.image.w - 5
 	  While FontManager.baseFont.getWidth(title) > maxWidth AND title.length > 4
 	  	title = title[..title.length-3]+".."
 	  Wend

 	  ProgrammeBlock.title = title
 	  If movie.isMovie = 0 Then ProgrammeBlock.title = title + " (" + movie.episodeNumber + "/" + movie.episodeCount + ")"
 	  ProgrammeBlock.Genre = Genre
 	  ProgrammeBlock.blocks = movie.blocks
 	  If Not List Then List = CreateList()
 	  ProgrammeBlock.Link = List.AddLast(ProgrammeBlock)
	  SortList(List)

 	  Player[owner].ProgrammePlan.AddProgramme(ProgrammeBlock.Programme)
 	  'Print "Player "+owner+" -Create block: added:"+programmeblock.Programme.title
 	  Return ProgrammeBlock
	End Function

	Function GetBlock:TProgrammeBlock(id:Int)
	  For Local _programmeBlock:TProgrammeBlock = EachIn TProgrammeBlock.List
	 	If _programmeBlock.uniqueID = id Then Return _programmeBlock
	  Next
	End Function

	Function GetActualProgrammeBlock:TProgrammeBlock(playerID:Int = -1, time:Int = -1, day:Int = -1)
		If playerID = -1 Then playerID = Game.playerID
		If time = -1 Then time = Game.GetActualHour()
		If day = -1 Then day = Game.day

		For Local Obj:TProgrammeBlock = EachIn TProgrammeBlock.list
			If Obj.owner = playerID
				Print Obj.programme.title + " from:" + Obj.Programme.sendtime + " to:" + (Obj.Programme.sendtime + Obj.Programme.blocks - 1)
				If (Obj.Programme.sendtime + Obj.Programme.blocks - 1) >= time And Obj.Programme.sendtime <= time And Obj.Programme.senddate = day Then Return Obj
			EndIf
  		Next
		Return Null
  	End Function

    'creates a programmeblock which is already dragged (used by movie/series-selection)
    'erstellt einen gedraggten Programmblock (genutzt von der Film- und Serienauswahl)
	Function CreateDragged:TProgrammeBlock(movie:TProgramme, parentMovie:TProgramme = Null, owner:Int =-1)
	  Local playerID:Int =0
	  If owner < 0 Then playerID = game.playerID Else playerID = owner
	  Local Genre:String
	  Local ProgrammeBlock:TProgrammeBlock=New TProgrammeBlock
	  ProgrammeBlock.SetStartConfig(MouseX(),MouseY(),playerID, 0)
 	  ProgrammeBlock.ParentProgramme= parentMovie
 	  TProgrammeBlock.LastUniqueID :+1
 	  ProgrammeBlock.dragged = 1
 	  TProgrammeBlock.AdditionallyDragged :+ 1


 	  ProgrammeBlock.Programme = New TProgramme
 	  ProgrammeBlock.Programme = Player[playerID].ProgrammePlan.CloneProgramme(movie)
 	  ProgrammeBlock.Programme.senddate = Game.daytoplan
 	  ProgrammeBlock.Programme.sendtime = Int(Floor((ProgrammeBlock.StartPos.y - 17) / 30))

      Genre = TProgramme.GetGenre(ProgrammeBlock.Programme.Genre)
 	  Local title :String = ProgrammeBlock.Programme.title
 	  While FontManager.baseFont.getWidth(title) > ProgrammeBlock.image.w - 5
 	  	title = title[..title.length-3]+".."
 	  Wend
 	  ProgrammeBlock.title = title
 	  ProgrammeBlock.Genre = Genre
 	  ProgrammeBlock.blocks = movie.blocks
 	  If parentMovie <>Null
 '	    ProgrammeBlock.title = parentMovie.title + " ("+movie.episode+"/"+parentMovie.episodecount+")"
 	    ProgrammeBlock.title = parentMovie.title
        Genre = TProgramme.GetGenre(parentMovie.Genre)
 	    ProgrammeBlock.Programme.relPrice = ProgrammeBlock.ParentProgramme.relPrice
 	    ProgrammeBlock.Programme.Outcome = ProgrammeBlock.ParentProgramme.Outcome
 	    ProgrammeBlock.Programme.blocks = ProgrammeBlock.ParentProgramme.blocks
  	  EndIf

 	  If Not List Then List = CreateList()
 	  ProgrammeBlock.Link = List.AddLast(ProgrammeBlock)
 	  'SortList List
	  SortList(List)
 	  Return ProgrammeBlock
	End Function

	Method SetDragable(_dragable:Int = 1)
		dragable = _dragable
	End Method

    Method Compare:Int(otherObject:Object)
       Local s:TProgrammeBlock = TProgrammeBlock(otherObject)
       If Not s Then Return 1                  ' Objekt nicht gefunden, an das Ende der Liste setzen
       If s.dragged = 0
           Return 1
       EndIf
       If s.dragged = 1
           Return 0
       EndIf
    End Method

    Method GetTimeOfBlock:Int(extx:Int=-1, exty:Int=-1)
    	Local locx:Int = Self.StartPos.x
    	Local locy:Int = Self.StartPos.y
    	If exty > 0 locx = exty
    	If extx > 0 locx = extx
    	'notfalls bei 394 und 37 locx  = startrectx
    	If locx >= 394 And locx <= 394 + width
    	  Return 12+(Int(Floor(locy - 17) / 30))
    	EndIf
    	If locx <= 67+width
    	  Return 1*(Int(Floor(locy - 17) / 30))
    	EndIf
    	Return -1
    End Method

    Method GetEndTimeOfBlock:Int(extx:Int=-1, exty:Int=-1, extblocks:Int = -1)
    	Local locx:Int = Self.StartPos.x
    	Local locy:Int = Self.StartPos.y
    	Local locblocks:Int = Self.blocks-1
    	If exty >= 0 locx = exty
    	If extx >= 0 locx = extx
    	If extblocks > 0 locblocks = extblocks-1

    	If locx >= 394 And locx <= 394 + width
    	  If exty + 30*locblocks > 374
'            Return 24+locblocks - Int(Floor(374-17 - locy)/30)
            Return locblocks - Int(Floor(374-17 - locy)/30)
          Else
            Return 12+locblocks+(Int(Floor(locy - 17) / 30))
          EndIf
    	EndIf
    	If locx <= 67+width
    	  If exty + 30*locblocks > 374
            Return 12 + locblocks - Int(Floor(374-17 - locy)/30)
          Else
      	    Return locblocks+1*(Int(Floor(locy - 17) / 30))
          EndIf
    	EndIf
    	Return -1
    End Method

    Method DraggingAllowed:Byte()
    	If dragable And State = 0 And owner=Game.playerID
    	  Return True
    	Else
    	  Return False
    	EndIf
    End Method

    Method DrawBlockPart(x:Int,y:Int,kind:Int, variant:string="")
    	If kind=1
			Assets.GetSprite("pp_programmeblock2"+variant).DrawClipped(x, y, x, y, -1, 30)
    	else
			Assets.GetSprite("pp_programmeblock2"+variant).DrawClipped(x, y - 30, x, y, -1, 15)
    	    If kind=2
				Assets.GetSprite("pp_programmeblock2"+variant).DrawClipped(x, y - 30 + 15, x, y + 15, -1, 15)
    	    Else
				Assets.GetSprite("pp_programmeblock2"+variant).DrawClipped(x, y - 30, x, y + 15, -1, -1)
    	    EndIf
	    EndIf
    End Method

	Function DrawAllShades()
	  For Local ProgBlock:TProgrammeBlock = EachIn TProgrammeBlock.List
        If ProgBlock.owner = Game.playerID And ProgBlock.dragged=1
	      'draw a shade of the programmeblock on its original position but not when just created and so dragged from its creation on
		  If (ProgBlock.StartPos.x = 394 Or ProgBlock.StartPos.x = 67) And (Abs(ProgBlock.pos.x - ProgBlock.StartPos.x) > 0 Or Abs(ProgBlock.pos.y - ProgBlock.StartPos.y) >0)
				SetAlpha 0.4
				If ProgBlock.blocks = 1
					ProgBlock.image.Draw(ProgBlock.StartPos.x, ProgBlock.StartPos.y)
				Else
					Local missedblocks:Int = 0
					ProgBlock.DrawBlockPart(ProgBlock.StartPos.x,ProgBlock.StartPos.y,1)
					If ProgBlock.blocks >= 3
					For Local i:Int = 0 To ProgBlock.blocks-3
						If ProgBlock.StartPos.y + (i + 1) * 30 < 374
							ProgBlock.DrawBlockPart(ProgBlock.StartPos.x,ProgBlock.StartPos.y + (i+1)*30,2)
						Else
						If ProgBlock.StartPos.x = 67
							ProgBlock.DrawBlockPart(394,17+(ProgBlock.blocks-3-i)*30,2)
						EndIf
						If ProgBlock.StartPos.x =394
							ProgBlock.DrawBlockPart(67 ,17+(ProgBlock.blocks-3-i)*30,2)
						EndIf
							missedblocks :+ 1
						EndIf
					Next
					EndIf
					If ProgBlock.StartPos.y + (ProgBlock.blocks-1)*30 < 374
					  ProgBlock.DrawBlockPart(ProgBlock.StartPos.x, ProgBlock.StartPos.y +(ProgBlock.blocks-1)*30,3)
					Else
					If ProgBlock.StartPos.x = 67
						ProgBlock.DrawBlockPart(394, 17 + (missedblocks) * 30, 3)
					Else If ProgBlock.StartPos.x = 394
						ProgBlock.DrawBlockPart(67, 17 + (missedblocks) * 30, 3)
					EndIf
					EndIf
				EndIf
				ProgBlock.DrawBlockText( TColor.Create(80,80,80), ProgBlock.startPos )
				SetAlpha 1.0
			EndIf
		EndIf
	  Next
	End Function

	Method GetState:Int()
     	State = 1
      If Game.day > Game.daytoplan Then State = 4
      If Game.day < Game.daytoplan Then State = 0
      If Game.day = Game.daytoplan
	    Local BlockTime:Int = GetTimeOfBlock()
'	    print "getState"
		If BlockTime          >  (Int(Floor((Game.minutesOfDayGone-5) / 60)))  Then State = 0  'normal
        If BlockTime          <= (Int(Floor((Game.minutesOfDayGone-5) / 60))) And GetTimeOfBlock()+blocks >= (Int(Floor(Game.minutesOfDayGone / 60)))  Then State = 2  'running
   	    If BlockTime+blocks-1 <  (Int(Floor((Game.minutesOfDayGone+5)  / 60))) Then State = 1  'runned
   	    If BlockTime          <  0                                 Then State = 0  'normal
      EndIf
	End Method

	'draw the programmeblock inclusive text
    'zeichnet den Programmblock inklusive Text
	Method Draw()
		'Draw dragged programmeblockgraphic
		If dragged = 1 Or Programme.senddate = Game.daytoplan 'out of gameplanner
			GetState()
			If dragged Then state = 0
			If State = 0 Then SetColor 255,255,255;dragable=1  'normal
			If State = 1 Then SetColor 200,255,200;dragable=0  'runned
			If State = 2 Then SetColor 250,230,120;dragable=0  'running
			If State = 4 Then SetColor 255,255,255;dragable=0  'old day

			local variant:string = ""
			if dragged = 1 and state=0 then variant = "_dragged"

			If blocks = 1
				Assets.GetSprite("pp_programmeblock1"+variant).Draw(pos.x, pos.y)
			Else
				Local missedblocks:Int = 0
				'top of block
				DrawBlockPart(pos.x,pos.y,1, variant)
				'middle part
				If blocks >= 3
					For Local i:Int = 0 To blocks-3
						If pos.y+(i+1)*30 < 374
							DrawBlockPart(pos.x,pos.y+(i+1)*30,2,variant)
						Else
							Select pos.x
								Case 67		DrawBlockPart(394,17+(blocks-3-i)*30,2,variant)
								Case 394	DrawBlockPart(67 ,17+(blocks-3-i)*30,2,variant)
							EndSelect
							missedblocks :+ 1
						EndIf
					Next
				EndIf
				'end part
				If pos.y+(blocks-1)*30 < 374
					DrawBlockPart(pos.x,pos.y+(blocks-1)*30,3,variant)
				Else
					Select pos.x
						Case 67		DrawBlockPart(394,17+(missedblocks)*30,3,variant)
						Case 394	DrawBlockPart(67 ,17+(missedblocks)*30,3,variant)
					EndSelect
				EndIf
			EndIf
			'text on block
			self.DrawBlockText(TColor.Create(50,50,50), self.pos)
			SetAlpha 1.0
		EndIf 'daytoplan switch
    End Method

    Method DrawBlockText(color:TColor = null, _pos:TPosition)
		SetColor 0,0,0
		FontManager.baseFont.DrawBlock(self.title, _pos.x + 5, _pos.y +2, self.image.w - 10, 18, 0, 0, 0, 0, True)
		if color <> null then color.set()
		If ParentProgramme<> Null
			FontManager.GetFont("Default", 11, ITALICFONT).Draw(Genre+"-Serie",_pos.x+5,_pos.y+18)
			FontManager.GetFont("Default", 11, ITALICFONT).Draw("Teil: " + Programme.episodeNumber + "/" + ParentProgramme.episodecount, _pos.x + 138, _pos.y + 18)
		Else
			FontManager.GetFont("Default", 11, ITALICFONT).Draw(Genre,_pos.x+5,_pos.y+18)
			If Programme.fsk18 <> 0 Then FontManager.GetFont("Default", 11, ITALICFONT).Draw("FSK 18!",_pos.x+138,_pos.y+18)
		EndIf
		SetColor 255,255,255
	End Method

    Method DeleteBlock()
      Print "delete programme:"+Self.Programme.title
      ReverseList TProgrammeBlock.List
      Player[Game.playerID].ProgrammePlan.RemoveProgramme(Self.Programme)
      'ListRemove TProgrammeBlock.List,(Self)
	  Self.Link.Remove()
    End Method

	Method GetBlockX:Int(time:Int)
		If time < 12 Then Return 67
		Return 394
	End Method

	Method GetBlockY:Int(time:Int)
		If time < 12 Then Return time * 30 + 17
		Return (time - 12) * 30 + 17
	End Method

    'remove from programmeplan
    Method DragBlock()
      'Print "removed programme:"+Self.Programme.title
      Player[game.playerID].ProgrammePlan.RefreshProgrammePlan( Self.Programme.senddate )
      If game.networkgame Then Network.SendPlanProgrammeChange(game.playerID, Self, 0)
    End Method

	'add to plan again
    Method DropBlock()
      Player[game.playerID].ProgrammePlan.RefreshProgrammePlan( Self.Programme.senddate )
      If game.networkgame Then Network.SendPlanProgrammeChange(game.playerID, Self, 1)
    End Method

    Function DrawAll(origowner:Int=0)
      SortList TProgrammeBlock.List
	  If TProgrammeBlock.AdditionallyDragged > 0 Then TProgrammeBlock.DrawAllShades()
      For Local ProgrammeBlock:TProgrammeBlock = EachIn TProgrammeBlock.List
      If ProgrammeBlock.owner = origowner 'or ProgrammeBlock.owner = Game.playerID
     	ProgrammeBlock.Draw()
      EndIf
      Next
    End Function

	Function UpdateAll(origowner:Int=0)
      Local gfxListenabled:Byte = 0
      If PPprogrammeList.enabled <> 0 Or PPcontractList.enabled <> 0 Then gfxListenabled = 1

      TProgrammeBlock.AdditionallyDragged = 0
      Local clickrecognized :Byte = 0
      'SortList TProgrammeBlock.List
      SortList TProgrammeBlock.List
	  TProgrammeBlock.DrawAllShades()
      For Local ProgrammeBlock:TProgrammeBlock = EachIn TProgrammeBlock.List
      If ProgrammeBlock.owner = Game.playerID And origowner = game.playerID Then
        If ProgrammeBlock.dragged = 0
   	      If ProgrammeBlock.pos.x = 67  ProgrammeBlock.timeset = (ProgrammeBlock.pos.y - 17) / 30
 	      If ProgrammeBlock.pos.x = 394 ProgrammeBlock.timeset = 12+ (ProgrammeBlock.pos.y - 17) / 30
        EndIf
        If ProgrammeBlock.dragged = 1 Then ProgrammeBlock.timeset = -1; Programmeblock.Programme.senddate = Game.daytoplan
        If gfxListenabled=0 And MOUSEMANAGER.IsHit(2) And ProgrammeBlock.dragged = 1
          Local missedblocks:Int = 0
          For Local i:Int = 0 To ProgrammeBlock.blocks
     	    	missedblocks :+ 1
          Next
          ProgrammeBlock.DeleteBlock() 'removes block from Programmeplan
          MOUSEMANAGER.resetKey(2)
        EndIf

        If gfxListenabled=0 And Not Clickrecognized And MOUSEMANAGER.IsHit(1) And MouseY()>17
          If ProgrammeBlock.dragged = 0
            If ProgrammeBlock.dragable = 1 And Programmeblock.State = 0 And ProgrammeBlock.Programme.senddate = Game.daytoplan
              Local missedblocks:Int = 0
              For Local i:Int = 0 To ProgrammeBlock.blocks
           	    If (ProgrammeBlock.pos.y+i*30) > 377
            	  If ProgrammeBlock.pos.x = 67
				  	If functions.IsIn(MouseX(), MouseY(), 394, 17+(ProgrammeBlock.blocks - missedblocks-1)*30, ProgrammeBlock.width, 1*30)
        		      	ProgrammeBlock.dragged = 1
            	    EndIf
		          Else
				  	If functions.IsIn(MouseX(), MouseY(), 67, 17+(ProgrammeBlock.blocks - missedblocks-1)*30, ProgrammeBlock.width, 1*30)
						ProgrammeBlock.dragged = 1
             	 	EndIf
                  End If
                Else
				  	If functions.IsIn(MouseX(), MouseY(), ProgrammeBlock.Pos.x, ProgrammeBlock.pos.y, ProgrammeBlock.width, 30*(ProgrammeBlock.blocks))
	                    ProgrammeBlock.dragged = 1
    				EndIf
                End If
   	    	    missedblocks :+ 1
   	    	    If programmeblock.dragged = 1 Then Exit
              Next
   	    	    If programmeblock.dragged = 1
   	    	      ProgrammeBlock.DragBlock()
   	    	    EndIf
    	    'reset a DnD-Zone when a programmeblock is dragged
    	    If programmeblock.dragged = 1
               Local missedblocks:Int = 0
          For Local i:Int = 0 To ProgrammeBlock.blocks

           	    If (ProgrammeBlock.StartPos.y+i*30) > 377
	          	  If ProgrammeBlock.StartPos.x = 67
 					TDragAndDrop.FindAndSetDragAndDropTargetUnUsed(ProgrammeBlock.DragAndDropList, 394,17+(ProgrammeBlock.blocks - missedblocks)*30)
                  ElseIf ProgrammeBlock.StartPos.x = 394
 					TDragAndDrop.FindAndSetDragAndDropTargetUnUsed(ProgrammeBlock.DragAndDropList, 67,17+(ProgrammeBlock.blocks - missedblocks)*30)
            	  End If
            	Else
				  TDragAndDrop.FindAndSetDragAndDropTargetUnUsed(ProgrammeBlock.DragAndDropList, Programmeblock.StartPos.x,ProgrammeBlock.StartPos.y+i*30)
                EndIf
     	    	missedblocks :+ 1
          Next
            EndIf
            'end reset


            EndIf
          Else 'drop dragged block
            Local DoNotDrag:Int = 0
            If gfxListenabled=0 And MOUSEMANAGER.IsHit(1)  And Programmeblock.State = 0

              For Local DragAndDrop:TDragAndDrop = EachIn ProgrammeBlock.DragAndDropList  		'loop through DnDs
                If DragAndDrop.Drop(MouseX(),MouseY(), "programmeblock") = 1 										'mouse within dnd-rect
	              For Local OtherProgrammeBlock:TProgrammeBlock = EachIn TProgrammeBlock.List   'loop through other pblocks
                   If OtherProgrammeBlock.owner = Game.playerID Then
                   'is there a programmeblock positioned at the desired place?

                    'is otherprogrammeblock not the same as our actual programmeblock? - on the same day
                    If OtherProgrammeBlock.id <> Programmeblock.id And..
                       OtherProgrammeBlock.Programme.senddate = ProgrammeBlock.Programme.senddate

                      Local dndtimeset:Int = -1
				  	  If DragAndDrop.rectx = 67  dndtimeset = (DragAndDrop.recty - 17) / 30		'timeset calc.
 	      			  If DragAndDrop.rectx = 394 dndtimeset = 12+ (DragAndDrop.recty - 17) / 30 'timeset calc.

					  'loop through aimed time + duration in scheduler
 					  For Local j:Int = dndtimeset To dndtimeset + ProgrammeBlock.blocks - 1

  					    If OtherProgrammeBlock.DraggingAllowed() = 0 And j >= OtherProgrammeBlock.timeset And j =< OtherProgrammeBlock.timeset + OtherProgrammeBlock.blocks-1
					      DoNotDrag = 1
					      clickrecognized = 1
					      ProgrammeBlock.dragged = 1
					      OtherProgrammeblock.dragged = 0
					    EndIf

					    'place block and drag the old one (under the new block)
 					    If DoNotDrag = 0 And j >= OtherProgrammeBlock.timeset And j < OtherProgrammeBlock.timeset + OtherProgrammeBlock.blocks-1
					      If OtherProgrammeBlock.DraggingAllowed()   'state=0 and dragable
                            OtherProgrammeBlock.dragged = 1
						    ProgrammeBlock.dragged      = 0
						    'DebugLog "swapped "+programmeblock.title+" with "+otherprogrammeblock.title
						  Else
						    'DebugLog "block under dragzone is running or has run: "+otherprogrammeblock.title
						  EndIf
					    EndIf

					    'block is changing side (>12am or >12pm)
 					    If j > 23 And OtherProgrammeBlock.timeset+OtherProgrammeBlock.blocks < j
					      OtherProgrammeBlock.dragged = 0
						  ProgrammeBlock.dragged      = 1
						  DoNotDrag = 1
						  'DebugLog "longer than 0am (have to look for free dropzone) so didn't drag "+ programmeblock.title

 					      If OtherProgrammeBlock.DraggingAllowed() And..
					         j+ProgrammeBlock.blocks-2-23 >= OtherProgrammeBlock.timeset And j+ProgrammeBlock.blocks-2-23 =< OtherProgrammeBlock.timeset + OtherProgrammeBlock.blocks-1
					        OtherProgrammeBlock.dragged = 1
					  	    ProgrammeBlock.dragged      = 0
						    DoNotDrag = 0
						    'DebugLog "but placed and dragged "+otherprogrammeblock.title
					      EndIf
					    EndIf
					    If otherProgrammeBlock.dragged = 1 Then otherProgrammeBlock.DragBlock()

					  Next
	                End If

                   EndIf
                  Next
                  If DoNotDrag <> 1
          Local missedblocks:Int = 0
          For Local i:Int = 0 To ProgrammeBlock.blocks
     	    	missedblocks :+ 1
          Next
		  			ProgrammeBlock.Pos.SetXY(DragAndDrop.rectx, DragAndDrop.recty)
					ProgrammeBlock.StartPos.SetPos(ProgrammeBlock.Pos)
                    clickrecognized = 1

			  	    ProgrammeBlock.Programme.senddate = Game.daytoplan 'hier noch aktuell machen
			  	    ProgrammeBlock.Programme.sendtime = Int(Floor((ProgrammeBlock.StartPos.y - 17) / 30))
                    If ProgrammeBlock.StartPos.x = 394 Then ProgrammeBlock.Programme.sendtime :+ 12
                    ProgrammeBlock.DropBlock()
                    Exit 'exit loop-each-dragndrop, we've already found the right position
                  EndIf
                EndIf
              Next
    ' endrem

				If ProgrammeBlock.IsAtStartPos() And DoNotDrag = 0 And (Game.day < Game.daytoplan Or (Game.day = Game.daytoplan And Game.GetActualHour() < ProgrammeBlock.GetTimeOfBlock(ProgrammeBlock.StartPos.x, ProgrammeBlock.StartPos.y)))
					ProgrammeBlock.dragged    = 0
					ProgrammeBlock.Pos.SetPos(ProgrammeBlock.StartPos)
				EndIf
            EndIf
          EndIf
		EndIf

        If ProgrammeBlock.dragged = 1
          TProgrammeBlock.AdditionallyDragged :+1
		  ProgrammeBlock.Pos.SetXY(MouseX() - ProgrammeBlock.width  /2 - TProgrammeBlock.AdditionallyDragged *5,..
          						   MouseY() - ProgrammeBlock.height /2 - TProgrammeBlock.AdditionallyDragged *5)
        EndIf
        If ProgrammeBlock.dragged = 0 Then ProgrammeBlock.Pos.SetPos(ProgrammeBlock.StartPos)
      EndIf
      Next
    End Function

End Type

Type TNewsBlock Extends TBlockGraphical
	Field title:String 				{saveload = "normal"}
	Field State:Int 		= 0 	{saveload = "normal"}
    Field sendslot:Int 		= -1 	{saveload = "normal"} 'which day this news is planned to be send?
    Field publishdelay:Int 	= 0		{saveload = "normal"} 'value added to publishtime when compared with Game.minutesOfDayGone to delay the "usabilty" of the block
    Field publishtime:Int 	= 0		{saveload = "normal"} '
    Field paid:Byte 		= 0 	{saveload = "normal"}
    Field news:TNews
	Field uniqueID:Int 		= 0 	{saveload = "normal"}
	Field Link:TLink
    Global LastUniqueID:Int 		= 0
    Global DragAndDropList:TList
    Global List:TList 				= CreateList()
    Global LeftListPosition:Int		= 0
    Global LeftListPositionMax:Int	= 4


	Function LoadAll(loadfile:TStream)
		TNewsBlock.List.Clear()
		'Print "cleared newsblocklist:"+TNewsBlock.List.Count()
		Local BeginPos:Int = Stream_SeekString("<NEWSB/>",loadfile)+1
		Local EndPos:Int = Stream_SeekString("</NEWSB>",loadfile)  -8
		Local strlen:Int = 0
		loadfile.Seek(BeginPos)

		TNewsBlock.lastUniqueID:Int        = ReadInt(loadfile)
		TNewsBlock.AdditionallyDragged:Int = ReadInt(loadfile)
		TNewsBlock.LeftListPosition:Int    = ReadInt(loadfile)
		TNewsBlock.LeftListPositionMax:Int = ReadInt(loadfile)
		Local NewsBlockCount:Int = ReadInt(loadfile)
		If NewsBlockCount > 0
			Repeat
				Local NewsBlock:TNewsBlock= New TNewsBlock
				strlen = ReadInt(loadfile); NewsBlock.title = ReadString(loadfile, strlen)
				NewsBlock.State      	= ReadInt(loadfile)
				NewsBlock.dragable   	= ReadByte(loadfile)
				NewsBlock.dragged    	= ReadByte(loadfile)
				NewsBlock.StartPos.Load(Null)
				NewsBlock.sendslot   	= ReadInt(loadfile)
				NewsBlock.publishdelay= ReadInt(loadfile)
				NewsBlock.publishtime	= ReadInt(loadfile)
				NewsBlock.paid 		= ReadByte(loadfile)
				NewsBlock.Pos.Load(Null)
				NewsBlock.owner		= ReadInt(loadfile)
				NewsBlock.uniqueID	= ReadInt(loadfile)
				Local NewsID:Int		= ReadInt(loadfile)
				If newsID >= 0 Then Newsblock.news = TNews.Load(Null) 'loadfile)

				NewsBlock.imageBaseName = "gfx_news_sheet"
				NewsBlock.width 		= gfx_contract.GetSprite("gfx_news_sheet0").w
				NewsBlock.Height		= gfx_contract.GetSprite("gfx_news_sheet0").h

				NewsBlock.Link = TNewsBlock.List.AddLast(NewsBlock)
				ReadString(loadfile,5) 'finishing string (eg. "|PRB|")
				Player[NewsBlock.owner].ProgrammePlan.AddNews(NewsBlock.news, NewsBlock.owner, NewsBlock.sendslot)
				Print "added '" + NewsBlock.news.title + "' to programmeplan for:"+newsBlock.owner
			Until loadfile.Pos() >= EndPos
		EndIf
		Print "loaded newsblocklist"
	End Function

	Function SaveAll()
		LoadSaveFile.xmlBeginNode("ALLNEWSBLOCKS")
			LoadSaveFile.xmlWrite("LASTUNIQUEID",		TNewsBlock.LastUniqueID)
			LoadSaveFile.xmlWrite("ADDITIONALLYDRAGGED",TNewsBlock.AdditionallyDragged)
			LoadSaveFile.xmlWrite("LEFTLISTPOSITION",	TNewsBlock.LeftListPosition)
			LoadSaveFile.xmlWrite("LEFTLISTPOSITIONMAX",TNewsBlock.LeftListPositionMax)
			'SaveFile.WriteInt(TNewsBlock.List.Count())
			For Local NewsBlock:TNewsBlock= EachIn TNewsBlock.List
				If NewsBlock <> Null Then NewsBlock.Save()
			Next
		LoadSaveFile.xmlCloseNode()
	End Function

	Method Save()
		LoadSaveFile.xmlBeginNode("NEWSBLOCK")
			Local typ:TTypeId = TTypeId.ForObject(Self)
			For Local t:TField = EachIn typ.EnumFields()
				If t.MetaData("saveload") = "normal" Or t.MetaData("saveload") = "normalExt"
					LoadSaveFile.xmlWrite(Upper(t.name()), String(t.Get(Self)))
				EndIf
			Next
			If Self.news <> Null
				LoadSaveFile.xmlWrite("NEWSID",		Self.news.id)
				Self.news.Save()
			Else
				LoadSaveFile.xmlWrite("NEWSID",		"-1")
			EndIf
		LoadSaveFile.xmlCloseNode()
	End Method

	Function Create:TNewsBlock(text:String="unknown", x:Int=0, y:Int=0, owner:Int=1, publishdelay:Int=0, usenews:TNews=Null)
	  Local LocObject:TNewsBlock=New TNewsBlock
	  LocObject.Pos		= TPosition.Create(x, y)
	  LocObject.StartPos= TPosition.Create(x, y)
 	  LocObject.owner = owner
 	  LocObject.State = 0
 	  locobject.publishdelay = publishdelay
 	  locobject.publishtime = Game.timeSinceBegin
 	  'hier noch als variablen uebernehmen
 	  LocObject.dragable = 1
 	  LocObject.sendslot = -1
 	  locObject.uniqueID = owner*30000 + TNewsBlock.LastUniqueID
 	  TNewsBlock.LastUniqueID :+1

	  If usenews = Null Then usenews = TNews.GetRandomNews()

 	  LocObject.news = New TNews
 	  LocObject.news  = TPlayerProgrammePlan.CloneNews(usenews)
 	  locobject.news.owner = owner

		Locobject.imageBaseName = "gfx_news_sheet"
		Locobject.imageBaseName = "gfx_news_sheet" '_dragged
		LocObject.width 		= Assets.GetSprite(Locobject.imageBaseName+"0").w
		LocObject.Height		= Assets.GetSprite(Locobject.imageBaseName+"0").h

 	  LocObject.title = LocObject.news.title
 	  If Not List Then List = CreateList()
 	  LocObject.Link = List.AddLast(LocObject)
 	  Player[owner].ProgrammePlan.AddNews(LocObject.news, owner)
 	  'SortList List
	  SortList(List)
 	  Return LocObject
	End Function

    Method Pay()
        Player[owner].finances[TFinancials.GetDayArray(Game.day)].PayNews(news.ComputePrice())
    End Method

	Function IncLeftListPosition:Int(amount:Int=1)
      If TNewsBlock.LeftListPositionMax-TNewsBlock.LeftListPosition > 4 Then TNewsBlock.LeftListPosition:+amount
	End Function

	Function DecLeftListPosition:Int(amount:Int=1)
      TNewsBlock.LeftListPosition:-amount
      If TNewsBlock.LeftListPosition < 0 Then TNewsBlock.LeftListPosition = 0
	End Function

	Method SetDragable(_dragable:Int = 1)
		dragable = _dragable
	End Method

    Method Compare:Int(otherObject:Object)
		Local s:TNewsBlock = TNewsBlock(otherObject)
		If Not s Then Return 1                  ' Objekt nicht gefunden, an das Ende der Liste setzen
		Return (dragged * 1000000 -(news.happenedday*10000+news.happenedhour*100+news.happenedminute))-(s.dragged * 1000000 -(s.news.happenedday*10000+s.news.happenedhour*100+s.news.happenedminute))
    End Method

    Method GetSlotOfBlock:Int()
    	If pos.x = 445 And dragged = 0 Then Return Int((StartPos.y - 19) / 87)
    	Return -1
    End Method

	Function GetBlock:TNewsBlock(id:Int)
		For Local _NewsBlock:TNewsBlock = EachIn TNewsBlock.List
			If _NewsBlock.uniqueID = id Then Return _Newsblock
		Next
	End Function

    'draw the Block inclusive text
	Method Draw()
		State = 0
		SetColor 255,255,255
		dragable=1
		local variant:string = ""
		If dragged = 1 And State = 0
			If self.AdditionallyDragged > 0 Then SetAlpha 1- 1/self.AdditionallyDragged * 0.25
			'variant = "_dragged"
		EndIf
		Assets.GetSprite(self.imageBaseName+news.genre+variant).Draw(Pos.x, Pos.y)


		'draw graphic
		If paid Then FontManager.GetFont("Default", 9).drawBlock("€ OK", pos.x + 1, pos.y + 65, 14, 25, 1, 50, 50, 50)
		FontManager.baseFontBold.drawBlock(news.title, pos.x + 15, pos.y + 3, 290, 15 + 8, 0, 20, 20, 20)
		FontManager.baseFont.drawBlock(news.description, pos.x + 15, pos.y + 18, 300, 45 + 8, 0, 100, 100, 100)
		SetAlpha 0.3
		FontManager.GetFont("Default", 9).drawBlock(news.GetGenre(news.Genre), pos.x + 15, pos.y + 72, 120, 15, 0, 0, 0, 0)
		SetAlpha 1.0
		FontManager.GetFont("Default", 12).drawBlock(news.ComputePrice() + ",-", pos.x + 220, pos.y + 70, 90, 15, 2, 0, 0, 0)
		If Game.day - news.happenedday = 0 Then FontManager.baseFont.drawBlock("Heute " + Game.GetFormattedExternTime(news.happenedhour, news.happenedminute) + " Uhr", pos.x + 90, pos.y + 72, 140, 15, 2, 0, 0, 0)
		If Game.day - news.happenedday = 1 Then FontManager.baseFont.drawBlock("(Alt) Gestern " + Game.GetFormattedExternTime(news.happenedhour, news.happenedminute) + " Uhr", pos.x + 90, pos.y + 72, 140, 15, 2, 0, 0, 0)
		If Game.day - news.happenedday = 2 Then FontManager.baseFont.drawBlock("(Alt) Vorgestern " + Game.GetFormattedExternTime(news.happenedhour, news.happenedminute) + " Uhr", pos.x + 90, pos.y + 72, 140, 15, 2, 0, 0, 0)
		SetColor 255, 255, 255
		SetAlpha 1.0
	End Method

	Function DrawAll(origowner:Int)
		SortList(TNewsBlock.List)
		For Local NewsBlock:TNewsBlock = EachIn TNewsBlock.List
			If origowner = NewsBlock.owner Or NewsBlock.owner = Game.playerID
				If (newsblock.dragged=1 Or (newsblock.pos.y > 0)) And (Newsblock.publishtime + Newsblock.publishdelay <= Game.timeSinceBegin) Then NewsBlock.Draw()
			EndIf
		Next
    End Function

    Function UpdateAll(origowner:Int)
		Local havetosort:Byte = 0
		Local dontpay:Int = 0
		Local number:Int = 0
		If TNewsBlock.LeftListPositionMax >=4
			If TNewsBlock.LeftListPosition+4 > TNewsBlock.LeftListPositionMax Then TNewsBlock.LeftListPosition = TNewsBlock.LeftListPositionMax-4
		Else
			TNewsBlock.LeftListPosition = 0
		EndIf

		SortList(TNewsBlock.List)

		For Local NewsBlock:TNewsBlock = EachIn TNewsBlock.List
			If NewsBlock.owner = Game.playerID
				If newsblock.GetSlotOfBlock() < 0 And (Newsblock.publishtime + Newsblock.publishdelay <= Game.timeSinceBegin)
					number :+ 1
					If number >= TNewsBlock.LeftListPosition And number =< TNewsBlock.LeftListPosition+4
						NewsBlock.Pos.SetXY(35, 22+88*(number-TNewsBlock.LeftListPosition   -1))
					Else
						NewsBlock.pos.SetXY(0, -100)
					EndIf
					NewsBlock.StartPos.SetPos(NewsBlock.Pos)
				EndIf
				If newsblock.GetSlotOfBlock() > 0 Then dontpay = 1
				If NewsBlock.dragged = 1 Then NewsBlock.sendslot = -1
				If MOUSEMANAGER.IsHit(2) And NewsBlock.dragged = 1
					'Game.IsMouseRightHit = 0
					TDragAndDrop.FindAndSetDragAndDropTargetUnUsed(newsBlock.DragAndDropList, newsBlock.StartPos.x, newsBlock.StartPos.y)
					ReverseList TNewsBlock.List
					If game.networkgame Then If network.IsConnected Then Network.SendPlanNewsChange(game.playerID, newsblock, 2)
					Player[Game.playerID].ProgrammePlan.RemoveNews(NewsBlock.news)
					Newsblock.Link.Remove()
					havetosort = 1
					MOUSEMANAGER.resetKey(2)
				EndIf

				If MOUSEMANAGER.IsHit(1)
					If NewsBlock.dragged = 0 And NewsBlock.dragable = 1 And NewsBlock.State = 0
						If functions.IsIn(MouseX(), MouseY(), NewsBlock.pos.x, NewsBlock.pos.y, NewsBlock.width, NewsBlock.height)
							NewsBlock.dragged = 1
							If game.networkgame Then If network.IsConnected Then Network.SendPlanNewsChange(game.playerID, newsblock, 0)
							Player[Game.playerID].ProgrammePlan.RemoveNews(NewsBlock.news)
						EndIf
					Else
						Local DoNotDrag:Int = 0
						if NewsBlock.State = 0
							NewsBlock.dragged = 0
							For Local DragAndDrop:TDragAndDrop = EachIn TNewsBlock.DragAndDropList
								If DragAndDrop.Drop(MouseX(),MouseY()) = 1
									For Local OtherNewsBlock:TNewsBlock = EachIn TNewsBlock.List
										If OtherNewsBlock.owner = Game.playerID
											'is there a NewsBlock positioned at the desired place?
											If MOUSEMANAGER.IsHit(1) And OtherNewsBlock.dragable = 1 And OtherNewsBlock.pos.x = DragAndDrop.rectx And OtherNewsBlock.pos.y = DragAndDrop.recty
												If OtherNewsBlock.State = 0
													OtherNewsBlock.dragged = 1
													If game.networkgame Then If network.IsConnected Then Network.SendPlanNewsChange(game.playerID, otherNewsBlock, 0)
													Player[Game.playerID].ProgrammePlan.RemoveNews(OtherNewsBlock.news)
													exit
												Else
													DoNotDrag = 1
												EndIf
											EndIf
										EndIf
									Next
									If DoNotDrag <> 1
										NewsBlock.Pos.SetXY(DragAndDrop.rectx, DragAndDrop.recty)
										TDragAndDrop.FindAndSetDragAndDropTargetUnUsed(newsBlock.DragAndDropList, newsBlock.StartPos.x, newsBlock.StartPos.y)
										TDragAndDrop.FindAndSetDragAndDropTargetUsed(newsBlock.DragAndDropList, newsBlock.pos.x, newsBlock.pos.y)
										NewsBlock.StartPos.SetPos(NewsBlock.Pos)
										Exit 'exit loop-each-dragndrop, we've already found the right position
									EndIf
								EndIf
							Next
							If NewsBlock.IsAtStartPos()
								If Not newsblock.paid And newsblock.pos.x > 400
									NewsBlock.Pay()
									newsblock.paid=True
								EndIf
								NewsBlock.dragged    = 0
								NewsBlock.Pos.SetPos(NewsBlock.StartPos)
								NewsBlock.sendslot   = Newsblock.GetSlotOfBlock()
								If NewsBlock.sendslot >0 And NewsBlock.sendslot < 4
									If game.networkgame Then If network.IsConnected Then Network.SendPlanNewsChange(game.playerID, newsblock, 1)
									Player[Game.playerID].ProgrammePlan.AddNews(NewsBlock.news, game.playerID, newsblock.sendslot)
								EndIf
								SortList TNewsBlock.List
							EndIf
						EndIf
					EndIf
				EndIf
				If NewsBlock.dragged = 1
					TNewsBlock.AdditionallyDragged = TNewsBlock.AdditionallyDragged +1
					NewsBlock.Pos.SetXY(MouseX() - NewsBlock.width /2 - TNewsBlock.AdditionallyDragged *5, MouseY() - NewsBlock.height /2 - TNewsBlock.AdditionallyDragged *5)
				EndIf
				If NewsBlock.dragged = 0
					NewsBlock.Pos.SetPos(NewsBlock.StartPos)
				EndIf
			EndIf
			If origowner = NewsBlock.owner Or NewsBlock.owner = Game.playerID
				If (newsblock.dragged=1 Or (newsblock.pos.y > 0)) And (Newsblock.publishtime + Newsblock.publishdelay <= Game.timeSinceBegin) Then NewsBlock.Draw()
			EndIf
		Next
		TNewsBlock.LeftListPositionMax = number
		TNewsBlock.AdditionallyDragged = 0
    End Function
End Type

'Contracts used in AdAgency
Type TContractBlocks Extends TBlockGraphical
  Field contract:TContract
  Field slot:Int = 0 {saveload = "normal"}
  Field Link:TLink
  Global DragAndDropList:TList = CreateList()
  Global List:TList = CreateList()
  Global AdditionallyDragged:Int =0

  Function LoadAll(loadfile:TStream)
    TContractBlocks.List.Clear()
	Print "cleared contractblocklist:"+TContractBlocks.List.Count()
    Local BeginPos:Int = Stream_SeekString("<CONTRACTB/>",loadfile)+1
    Local EndPos:Int = Stream_SeekString("</CONTRACTB>",loadfile)  -12
    'Local strlen:Int = 0
    loadfile.Seek(BeginPos)
    TContractBlocks.AdditionallyDragged:Int = ReadInt(loadfile)
	Local ContractBlockCount:Int = ReadInt(loadfile)
	If ContractBlockCount > 0
	Repeat
      Local ContractBlock:TContractBlocks= New TContractBlocks
	  ContractBlock.Pos.Load(Null)
	  ContractBlock.OrigPos.Load(Null)
	  Local ContractID:Int  = ReadInt(loadfile)
	  If ContractID >= 0
	    ContractBlock.contract = TContract.GetContract(ContractID)
		Local targetgroup:Int = ContractBlock.contract.targetgroup
		If targetgroup > 3 Or targetgroup <0 Then targetgroup = 0
 	  	ContractBlock.image 	= gfx_contract.GetSprite("Contract" + targetgroup)      'contract.targetgroup]
		ContractBlock.image_dragged = gfx_contract.GetSprite("ContractDragged" + targetgroup)
 	  	ContractBlock.width		= ContractBlock.image.w
 	  	ContractBlock.Height	= ContractBlock.image.h
	  EndIf
	  ContractBlock.dragable= ReadInt(loadfile)
	  ContractBlock.dragged = ReadInt(loadfile)
	  ContractBlock.slot	= ReadInt(loadfile)
		ContractBlock.StartPos.Load(Null)
	  ContractBlock.owner   = ReadInt(loadfile)
	  ContractBlock.Link = TContractBlocks.List.AddLast(ContractBlock)
	  ReadString(loadfile,5) 'finishing string (eg. "|PRB|")
	Until loadfile.Pos() >= EndPos
	EndIf
	Print "loaded contractblocklist"
  End Function

	Function SaveAll()
		Local ContractCount:Int = 0
		LoadSaveFile.xmlBeginNode("ALLCONTRACTBLOCKS")
			LoadSaveFile.xmlWRITE("ADDITIONALLYDRAGGED"		, TContractBlocks.AdditionallyDragged)
			For Local ContractBlock:TContractBlocks= EachIn TContractBlocks.List
				If ContractBlock <> Null Then If ContractBlock.owner <= 0 Then ContractCount:+1
		    Next
			LoadSaveFile.xmlWRITE("CONTRACTCOUNT"				, ContractCount)
			For Local ContractBlock:TContractBlocks= EachIn TContractBlocks.List
				If ContractBlock <> Null Then ContractBlock.Save()
			Next
		LoadSaveFile.xmlCloseNode()
	End Function

	Method Save()
		LoadSaveFile.xmlBeginNode("CONTRACTBLOCK")
			Local typ:TTypeId = TTypeId.ForObject(Self)
			For Local t:TField = EachIn typ.EnumFields()
				If t.MetaData("saveload") = "normal" Or t.MetaData("saveload") = "normalExt" Or t.MetaData("saveload") = "normalExtB"
					LoadSaveFile.xmlWrite(Upper(t.name()), String(t.Get(Self)))
				EndIf
			Next
			If Self.contract <> Null
				LoadSaveFile.xmlWrite("CONTRACTID",		Self.contract.id)
			Else
				LoadSaveFile.xmlWrite("CONTRACTID",		"-1")
			EndIf
		LoadSaveFile.xmlCloseNode()
	End Method

  Function ContractsToPlayer:Int(playerID:Int)
   SortList(TContractBlocks.List)
   	For Local locObject:TContractBlocks = EachIn TContractBlocks.List
     If locobject.pos.x > 520 And locobject.owner <= 0
       locobject.owner = playerID
       If game.networkgame
	     Local ContractArray:TContract[1]
		 ContractArray[0] = locobject.contract
         If network.IsConnected Then Network.SendContract(game.playerID, ContractArray)
		 ContractArray = Null
       Else
         Player[playerID].ProgrammeCollection.AddContract(locobject.contract,playerID)
       EndIf
      Local x:Int=0
      Local y:Int = 0

	  x = 285 + locObject.slot * LocObject.image.w
      y = 300 - 10 - LocObject.image.h - locobject.slot * 7
	  LocObject.Pos.SetXY(x, y)
	  LocObject.OrigPos.SetXY(x, y)
	  LocObject.StartPos.SetXY(x, y)
 	  LocObject.dragable = 1
 	  locobject.contract = TContract.GetRandomContract()
	  If locobject.contract <> Null
        Local targetgroup:Int = Locobject.contract.targetgroup
        If targetgroup > 3 Or targetgroup <0 Then targetgroup = 0
	 	  Locobject.image = gfx_contract.GetSprite("Contract" + targetgroup)      'contract.targetgroup]
 		  Locobject.image_dragged = gfx_contract.GetSprite("ContractDragged" + targetgroup)
	  EndIf
		locobject.owner = 0
     EndIf
    Next
  End Function

  Function RemoveContractFromSuitcase(contract:TContract)
	If contract <> Null
	  For Local ContractBlock:TContractBlocks =EachIn TContractBlocks.List
	    If ContractBlock.contract.id = contract.id
		  Print "removing contractblock (success)"
		  ContractBlock.Link.Remove()
		EndIf
	  Next
	End If
  End Function

  'if owner = 0 then its a block of the adagency, otherwise it's one of the player'
  Function Create:TContractBlocks(contract:TContract, slot:Int=0, owner:Int=0)
	  Local LocObject:TContractBlocks=New TContractBlocks
      Local x:Int=0
      Local y:Int=0
      Local targetgroup:Int = contract.targetgroup
      If targetgroup > 3 Or targetgroup <0 Then targetgroup = 0
 	  Locobject.image = gfx_contract.GetSprite("Contract" + targetgroup)    'contract.targetgroup]
 	  Locobject.image_dragged = gfx_contract.GetSprite("ContractDragged" + targetgroup)
 	  LocObject.width = LocObject.image.w
 	  LocObject.Height = LocObject.image.h

	  x = 285 + slot * LocObject.image.w
      y = 300 - 10 - LocObject.image.h - slot * 7
	  LocObject.Pos			= TPosition.Create(x, y)
	  LocObject.OrigPos		= TPosition.Create(x, y)
	  LocObject.StartPos	= TPosition.Create(x, y)
 	  LocObject.slot = slot
 	  locObject.owner = owner
 	  LocObject.dragable = 1
 	  LocObject.contract = contract
 	  If Not List Then List = CreateList()
 	  LocObject.Link = List.AddLast(LocObject)
 	  SortList List

If owner = 0
      Local DragAndDrop:TDragAndDrop = New TDragAndDrop
 	    DragAndDrop.slot = slot + 200
 	    DragAndDrop.rectx = x
 	    DragAndDrop.recty = y
 	    DragAndDrop.used = 1
 	    DragAndDrop.rectw = LocObject.image.w
 	    DragAndDrop.recth = LocObject.image.h
        TContractBlocks.DragAndDropList.AddLast(DragAndDrop)
Else
      LocObject.dragable = 0
EndIf
 	  Return LocObject
	End Function

	Method SetDragable(_dragable:Int = 1)
		dragable = _dragable
	End Method

    Method Compare:Int(otherObject:Object)
       Local s:TContractBlocks = TContractBlocks(otherObject)
       If Not s Then Return 1                  ' Objekt nicht gefunden, an das Ende der Liste setzen
  '      DebugLog s.title + " "+s.sendtime + " "+sendtime + " "+((dragged * 100 * sendtime + sendtime)-(s.dragged * 100 * s.sendtime + sendtime))
        Return (dragged * 100)-(s.dragged * 100)
    End Method


    'draw the Block inclusive text
    'zeichnet den Block inklusive Text
    Method Draw()
      SetColor 255,255,255  'normal

      If dragged = 1
    	If TContractBlocks.AdditionallyDragged > 0 Then SetAlpha 1- 1/TContractBlocks.AdditionallyDragged * 0.25
		gfx_contract.GetSprite("ContractDragged" + contract.targetgroup).Draw(Pos.x + 6, Pos.y)
'     	DrawImage(image_dragged,x+6,y)
      Else
        If Pos.x > 520
            If dragable = 0 Then SetColor 200,200,200
			gfx_contract.GetSprite("ContractDragged" + contract.targetgroup).Draw(Pos.x, Pos.y)
         	'DrawImage(image_dragged,x,y)
            If dragable = 0 Then SetColor 255,255,255
        Else
			gfx_contract.GetSprite("Contract" + contract.targetgroup).Draw(Pos.x, Pos.y)
        	'DrawImage(image, x, y)
        EndIf
      EndIf
      SetAlpha 1
    End Method

	Function DrawAll(DraggingAllowed:Byte)
      Local localslot:Int = 0 'slot in suitcase

      SortList TContractBlocks.List
      For Local locObject:TContractBlocks = EachIn TContractBlocks.List
	   If locObject.contract <> Null
     	If locobject.owner = Game.playerID
     	  locobject.Pos.SetXY(550 + LocObject.image.w * localslot, 87)
		  locobject.StartPos.SetPos(locobject.Pos)
     	  locobject.dragable = 0
		  locobject.slot = localslot
     	  localslot:+1
     	End If
        If locobject.owner <= 0 Or locobject.owner = Game.playerID
     	  locObject.Draw()
        EndIf
	   EndIf 'ungleich null
      Next
  End Function

    Function UpdateAll(DraggingAllowed:Byte)
'      Local havetosort:Byte = 0
      Local number:Int = 0
      Local localslot:Int = 0 'slot in suitcase

      SortList TContractBlocks.List
      For Local locObject:TContractBlocks = EachIn TContractBlocks.List
	   If locObject.contract <> Null
     	If locobject.owner = Game.playerID
     	  locobject.Pos.SetXY(550 + LocObject.image.w * localslot, 87)
		  locobject.StartPos.SetPos(locobject.Pos)
     	  locobject.dragable = 0
		  locobject.slot = localslot
     	  localslot:+1
     	End If
      If DraggingAllowed And locobject.owner <= 0
        number :+ 1
        If MOUSEMANAGER.IsHit(2) And locObject.dragged = 1
			locObject.Pos.SetPos(locObject.StartPos)
          MOUSEMANAGER.resetKey(2)
        EndIf

        If MOUSEMANAGER.IsHit(1)
          If locObject.dragged = 0 And locObject.dragable = 1
            If functions.IsIn(MouseX(), MouseY(), locObject.Pos.x, locObject.Pos.y, locObject.width-1, locObject.height)
              locObject.dragged = 1
      		  For Local OtherlocObject:TContractBlocks = EachIn TContractBlocks.List
			    If OtherLocObject.dragged And OtherLocObject <> locObject
					TPosition.SwitchPos(locObject.StartPos, OtherLocObject.StartPos)
					OtherLocObject.dragged = 0
			    End If
			  Next
              TDragAndDrop.FindAndSetDragAndDropTargetUnUsed(locObject.DragAndDropList, locObject.StartPos.x, locObject.StartPos.y)
			  MouseManager.resetKey(1)
            EndIf
          Else
            'Local DoNotDrag:Int = 0
            Local realDNDfound:Int = 0
              locObject.dragged = 0
              realDNDfound = 0
              For Local DragAndDrop:TDragAndDrop = EachIn TContractBlocks.DragAndDropList
                If DragAndDrop.CanDrop(MouseX(), MouseY()) = 1 And (DragAndDrop.rectx < 550 Or DragAndDrop.rectx > 550 + locobject.image.w * (localslot - 1))
                  For Local OtherlocObject:TContractBlocks= EachIn TContractBlocks.List
                   If DraggingAllowed And otherlocobject.owner <= 0
                     'is there a NewsBlock positioned at the desired place?
                      If MOUSEMANAGER.IsHit(1) And OtherlocObject.dragable = 1 And OtherlocObject.Pos.x = DragAndDrop.rectx And OtherlocObject.Pos.y = DragAndDrop.recty
                         OtherlocObject.dragged = 1
                         TDragAndDrop.FindAndSetDragAndDropTargetUnUsed(OtherlocObject.DragAndDropList, OtherlocObject.StartPos.x, OtherlocObject.StartPos.y)
           	         EndIf
                   EndIf
                  Next
					LocObject.Pos.SetXY(DragAndDrop.rectx, DragAndDrop.recty)
					TDragAndDrop.FindAndSetDragAndDropTargetUsed(locObject.DragAndDropList, locObject.StartPos.x, locObject.StartPos.y)
					LocObject.StartPos.SetPos(LocObject.Pos)
                    realDNDfound =1
                    Exit 'exit loop-each-dragndrop, we've already found the right position
                EndIf
              Next
              'suitcase as dndzone
              If Not realDNDfound And functions.IsIn(MouseX(),MouseY(),540,70,190,100)
              	For Local DragAndDrop:TDragAndDrop = EachIn TContractBlocks.DragAndDropList
              		If functions.IsIn(DragAndDrop.rectx, DragAndDrop.recty, 540,70,190,100)
              		  If DragAndDrop.rectx >= 540 + LocObject.image.w * (localslot)
              		  If DragAndDrop.used = 0 'and DragAndDrop.slot > (localslot) Then
              		    DragAndDrop.used =1
						LocObject.Pos.SetXY(DragAndDrop.rectx, DragAndDrop.recty)
              			TDragAndDrop.FindAndSetDragAndDropTargetUsed(locObject.DragAndDropList, locObject.StartPos.x, locObject.StartPos.y)
                        'DebugLog "suitcase-drop "+draganddrop.rectx
						LocObject.StartPos.SetPos(LocObject.Pos)
                        Exit 'exit loop-each-dragndrop, we've already found the right position
              		  End If
              		  EndIf
                	End If
              	Next
              End If
              'no drop-area under Adblock (otherwise this part is not executed - "exit"), so reset position
			  If LocObject.IsAtStartPos()
      		    locObject.dragged = 0
				LocObject.Pos.SetPos(LocObject.StartPos)
  				SortList TContractBlocks.List
              EndIf
            EndIf
         EndIf

        If locObject.dragged = 1
          TContractBlocks.AdditionallyDragged :+1
		  LocObject.Pos.SetXY(MouseX() - locObject.width /2 -  TContractBlocks.AdditionallyDragged *5,..
							  MouseY() - locObject.height /2 - TContractBlocks.AdditionallyDragged *5)
		Else
			LocObject.Pos.SetPos(LocObject.StartPos)
        EndIf
      EndIf
	  EndIf 'ungleich null
      Next
        TContractBlocks.AdditionallyDragged = 0
  End Function

End Type

'Programmeblocks used in MovieAgency
Type TMovieAgencyBlocks Extends TBlockGraphical
  Field Programme:TProgramme
  Field slot:Int = 0 {saveload = "normal"}
  Field Link:TLink
  Global DragAndDropList:TList = CreateList()
  Global List:TList = CreateList()
  Global AdditionallyDragged:Int =0
  Global DebugMode:Byte = 0
  Global HoldingType:Byte = 0

  Function LoadAll(loadfile:TStream)
    TMovieAgencyBlocks.List.Clear()
	Print "cleared movieagencyblocks:" + TMovieAgencyBlocks.List.Count()
    Local BeginPos:Int = Stream_SeekString("<MOVIEAGENCYB/>", loadfile) + 1
    Local EndPos:Int = Stream_SeekString("</MOVIEAGENCYB>",loadfile)  -15
    loadfile.Seek(BeginPos)
    TMovieAgencyBlocks.AdditionallyDragged:Int = ReadInt(loadfile)
	Local MovieAgencyBlocksCount:Int = ReadInt(loadfile)
	If MovieAgencyBlocksCount > 0
	Repeat
      Local MovieAgencyBlocks:TMovieAgencyBlocks = New TMovieAgencyBlocks
	  MovieAgencyBlocks.Pos.Load(Null)
	  MovieAgencyBlocks.OrigPos.Load(Null)
	  MovieAgencyBlocks.StartPos.Load(Null)
	  MovieAgencyBlocks.StartPosBackup.Load(Null)
	  Local ProgrammeID:Int  = ReadInt(loadfile)
	  If ProgrammeID >= 0
	    MovieAgencyBlocks.Programme = TProgramme.GetProgramme(ProgrammeID)
        Local targetgroup:Int = MovieAgencyBlocks.Programme.Genre
        If targetgroup > 3 Or targetgroup <0 Then targetgroup = 0
 	    MovieAgencyBlocks.width  = Assets.GetSprite("gfx_movie0").w-1
 	    MovieAgencyBlocks.height = Assets.GetSprite("gfx_movie0").h
	  EndIf
	  MovieAgencyBlocks.dragable= ReadInt(loadfile)
	  MovieAgencyBlocks.dragged = ReadInt(loadfile)
	  MovieAgencyBlocks.slot	= ReadInt(loadfile)
	  MovieAgencyBlocks.StartPos.Load(Null)
	  MovieAgencyBlocks.owner   = ReadInt(loadfile)
	  MovieAgencyBlocks.Link = TMovieAgencyBlocks.List.AddLast(MovieAgencyBlocks)

	  ReadString(loadfile,5) 'finishing string (eg. "|PRB|")
	Until loadfile.Pos() >= EndPos
	EndIf
	Print "loaded movieagencyblocks"
  End Function

	Function SaveAll()
		Local MovieAgencyBlocksCount:Int = 0
		LoadSaveFile.xmlBeginNode("ALLMOVIEAGENCYBLOCKS")
			LoadSaveFile.xmlWrite("ADDITIONALLYDRAGGED",	TMovieAgencyBlocks.AdditionallyDragged)
			For Local MovieAgencyBlocks:TMovieAgencyBlocks= EachIn TMovieAgencyBlocks.List
				If MovieAgencyBlocks <> Null Then If MovieAgencyBlocks.owner <= 0 Then MovieAgencyBlocksCount:+1
			Next
			LoadSaveFile.xmlWrite("MOVIEAGENCYBLOCKSCOUNT",	MovieAgencyBlocksCount)
			For Local MovieAgencyBlocks:TMovieAgencyBlocks= EachIn TMovieAgencyBlocks.List
				If MovieAgencyBlocks <> Null Then MovieAgencyBlocks.Save()
			Next
		LoadSaveFile.xmlCloseNode()
	End Function

	Method Save()
		LoadSaveFile.xmlBeginNode("MOVIEAGENCYBLOCK")
			Local typ:TTypeId = TTypeId.ForObject(Self)
			For Local t:TField = EachIn typ.EnumFields()
				If t.MetaData("saveload") = "normal" Or t.MetaData("saveload") = "normalExt"
					LoadSaveFile.xmlWrite(Upper(t.name()), String(t.Get(Self)))
				EndIf
			Next
			If Self.Programme <> Null
				LoadSaveFile.xmlWrite("PROGRAMMEID", Self.programme.pid)
			Else
				LoadSaveFile.xmlWrite("PROGRAMMEID",		"-1")
			EndIf
		LoadSaveFile.xmlCloseNode()
	End Method


  Method Buy:Int(PlayerID:Int = -1)
  	If PlayerID = -1 Then PlayerID = Game.playerID
	If Player[PlayerID].finances[TFinancials.GetDayArray(Game.day)].PayMovie(Programme.ComputePrice())
  		owner = PlayerID
		Programme.used = PlayerID
		Return 1
	EndIf
	Return 0
  End Method

  Method Sell(bymakler:Byte=0, PlayerID:Int=-1)
  	If PlayerID = -1 Then PlayerID = Game.playerID
    If Game.networkgame Then If Network.IsConnected Then Network.SendProgrammeCollectionChange(PlayerID, programme, 0) 'remove from collection
    Player[PlayerID].finances[TFinancials.GetDayArray(Game.day)].SellMovie(Programme.ComputePrice())
    'If bymakler Then TMovieAgencyBlocks.RemoveBlockByProgramme(Programme, owner)
	Self.StartPos.SetPos(Self.StartPosBackup)
	Self.StartPosBackup.SetY(0)
	If Self.StartPos.y < 240 And Self.StartPos.x > 760 Then Self.SetCoords(Self.StartPos.x,Self.StartPos.y,Self.StartPos.x,Self.StartPos.y)
	programme.used = 0
   	owner = 0
    If Self.DebugMode=1 Then Print "Programme "+Programme.title +" sold"
  End Method

  Function RemoveBlockByProgramme(programme:TProgramme, playerID:Int=0)
    If programme <> Null
	  Local movieblockarray:Object[]
	  movieblockarray = TMovieAgencyBlocks.List.ToArray()
	  For Local j:Int = 0 To movieblockarray.Length-1
        If TMovieAgencyBlocks(movieblockarray[j]).Programme <> Null
	      If TMovieAgencyBlocks(movieblockarray[j]).Programme.title = programme.title
  	        movieblockarray[j] = Null
          EndIf
	    EndIf
	  Next
	  TMovieAgencyBlocks.List.Clear()
	  TMovieAgencyBlocks.List = TList.FromArray(movieblockarray)
	EndIf
  End Function

  'refills missing blocks in the movieagency
  'has to be excluded from other functions to make it the way, that a player has to leave the movieagency
  'to get "new" movies to buy
  Function ReFillBlocks:Int()
    Local movierow:Byte[11]
    Local seriesrow:Byte[7]
	For Local locObject:TMovieAgencyBlocks = EachIn TMovieAgencyBlocks.List
      If locobject.Programme <> Null
	    If locobject.Pos.y = 134-70     Then movierow[ Int( (locobject.Pos.x-600)/15 ) ] = 1
        If locobject.Pos.y = 134-70+110 Then seriesrow[ Int( (locobject.Pos.x-600)/15 ) ] = 1
      Else
	    If locobject.Pos.y = 134-70     Then locobject.Programme = TProgramme.GetRandomMovie()
        If locobject.Pos.y = 134-70+110 Then locobject.Programme = TProgramme.GetRandomSerie()
	  EndIf
	Next
	For Local i:Byte = 0 To seriesrow.length-2
	  If seriesrow[i] <> 1 Then  TMovieAgencyBlocks.Create(TProgramme.GetRandomSerie(),i+20, 0)
	Next
	For Local i:Byte = 0 To movierow.length-2
	  If movierow[i] <> 1 Then TMovieAgencyBlocks.Create(TProgramme.GetRandomMovie(),i, 0)
	Next
  End Function

  Function ProgrammeToPlayer:Int(playerID:Int)
    TArchiveProgrammeBlocks.ClearSuitcase(playerID)
   SortList(TMovieAgencyBlocks.List)
   	For Local locObject:TMovieAgencyBlocks = EachIn TMovieAgencyBlocks.List
     If locobject.Pos.y > 240 And locobject.owner = playerID
       If     locobject.Programme.isMovie Then Player[playerID].ProgrammeCollection.AddMovie(locobject.Programme,playerID)
       If Not locobject.Programme.isMovie Then Player[playerID].ProgrammeCollection.AddSerie(locobject.Programme,playerID)
      Local x:Int=0
      Local y:Int=0
      x=600+locobject.slot*15 'ImageWidth(gfx_movie[0])
      y=134-70 'ImageHeight(gfx_movie[0])
 	  If locobject.slot >= 20 And locobject.slot <= 30 '2. Reihe: Serien
      x=600+(locobject.slot-20)*15 'ImageWidth(gfx_movie[0])
      y=134-70 + 110'ImageHeight(gfx_movie[0])
      EndIf
	  LocObject.Pos.SetXY(x, y)
	  LocObject.OrigPos.SetXY(x, y)
	  LocObject.StartPos.SetXY(x, y)
 	  locobject.owner = 0

 	  LocObject.dragable = 1
	  If locobject.Programme.isMovie
			locobject.Programme = TProgramme.GetRandomMovie(-1)
	  Else
			locobject.Programme = TProgramme.GetRandomSerie(-1)
	  EndIf
	 EndIf
    Next
	TMovieAgencyBlocks.ReFillBlocks()
  End Function

  'if owner = 0 then its a block of the adagency, otherwise it's one of the player'
  Function Create:TMovieAgencyBlocks(Programme:TProgramme, slot:Int=0, owner:Int=0)
	If Programme <> Null
	  Local LocObject:TMovieAgencyBlocks=New TMovieAgencyBlocks
      Local x:Int=0
      Local y:Int=0
      x=600+slot*15 'ImageWidth(gfx_movie[0])
      y=134-70 'ImageHeight(gfx_movie[0])
 	  If slot >= 20 And slot <= 30 '2. Reihe: Serien
      x=600+(slot-20)*15 'ImageWidth(gfx_movie[0])
      y=134-70 + 110'ImageHeight(gfx_movie[0])
      EndIf
 	  If owner > 0 Then y = 260
	  LocObject.Pos			=TPosition.Create(x, y)
	  LocObject.OrigPos		=TPosition.Create(x, y)
	  LocObject.StartPos	=TPosition.Create(x, y)
	  LocObject.StartPosBackup =TPosition.Create(x, y)
 	  LocObject.slot = slot
 	  locObject.owner = owner
 	  'hier noch als variablen uebernehmen
 	  LocObject.dragable = 1
      Local targetgroup:Int = Programme.Genre
      If targetgroup > 3 Or targetgroup <0 Then targetgroup = 0
 	  LocObject.width  = Assets.GetSprite("gfx_movie0").w-1
 	  LocObject.height = Assets.GetSprite("gfx_movie0").h
 	  LocObject.Programme = Programme
 	  If Not List Then List = CreateList()
 	  LocObject.Link = List.AddLast(LocObject)
 	  SortList List

If owner = 0
      Local DragAndDrop:TDragAndDrop = New TDragAndDrop
 	    DragAndDrop.slot = slot + 200
 	    DragAndDrop.rectx = x
 	    DragAndDrop.recty = y
 	    DragAndDrop.used = 1
 	    DragAndDrop.rectw = Assets.GetSprite("gfx_movie0").w
 	    DragAndDrop.recth = Assets.GetSprite("gfx_movie0").h
        TMovieAgencyBlocks.DragAndDropList.AddLast(DragAndDrop)
Else
      LocObject.dragable = 0
EndIf
'      Print "created movieblock"+locobject.y
 	  Return LocObject
	 EndIf
    Return Null
  End Function

	Method SetDragable(_dragable:Int = 1)
		dragable = _dragable
	End Method

    Method Compare:Int(otherObject:Object)
       Local s:TMovieAgencyBlocks = TMovieAgencyBlocks(otherObject)
       If Not s Then Return 1                  ' Objekt nicht gefunden, an das Ende der Liste setzen
  '      DebugLog s.title + " "+s.sendtime + " "+sendtime + " "+((dragged * 100 * sendtime + sendtime)-(s.dragged * 100 * s.sendtime + sendtime))
        Return (dragged * 100)-(s.dragged * 100)
    End Method

    Method GetSlotOfBlock:Int()
    	If Pos.x = 589
    	  Return 12+(Int(Floor(StartPos.y- 17) / 30))
    	EndIf
    	If Pos.x = 262
    	  Return 1*(Int(Floor(StartPos.y - 17) / 30))
    	EndIf
    	Return -1
    End Method

    'draw the Block inclusive text
    'zeichnet den Block inklusive Text
    Method Draw()
      SetColor 255,255,255  'normal
	    dragable = 1
		If Programme.ComputePrice() > Player[Game.playerID].finances[0].money And..
           owner <> Game.playerID And..
           dragged = 0  Then dragable = 0

      If dragged = 1
    	If TMovieAgencyBlocks.AdditionallyDragged > 0 Then SetAlpha 1- 1/TMovieAgencyBlocks.AdditionallyDragged * 0.25
       	If Programme.Genre < 9
			Assets.GetSprite("gfx_movie"+Programme.Genre).Draw(Pos.x+7, Pos.y)
     	Else
			Assets.GetSprite("gfx_movie0").Draw(Pos.x+7, Pos.y)
     	EndIf
      Else
        If Pos.x > 520
            If dragable = 0 Then SetAlpha 0.7;SetColor 200,200,200
        EndIf
       	If Programme.Genre < 9
			Assets.GetSprite("gfx_movie"+Programme.Genre).Draw(Pos.x, Pos.y)
     	Else
			Assets.GetSprite("gfx_movie0").Draw(Pos.x, Pos.y)
     	EndIf
      EndIf
      SetColor 255,255,255
      SetAlpha 1
    End Method

   Function DrawAll(DraggingAllowed:Byte)
      SortList TMovieAgencyBlocks.List
      For Local locObject:TMovieAgencyBlocks = EachIn TMovieAgencyBlocks.List
       If locobject.Programme <> Null
         If locobject.owner <= 0 Or locobject.owner = Game.playerID
       	  locObject.Draw()
         EndIf
	   EndIf
      Next
  End Function

	Function UpdateAll(DraggingAllowed:Byte)
		Local localslot:Int = 0 								'slot in suitcase
		Local imgWidth:Int  = Assets.GetSprite("gfx_movie0").w

		TMovieAgencyBlocks.holdingType = 0						'reset type of holding block (0 = no block, 1 = own, 2 = agency)
		TMovieAgencyBlocks.AdditionallyDragged = 0				'reset additional dragged objects
		SortList TMovieAgencyBlocks.List						'sort blocklist

		'search for obj of the player (and set coords from left to right of suitcase)
		For Local locObj:TMovieAgencyBlocks = EachIn TMovieAgencyBlocks.List
			If locObj.Programme <> Null
			'	locObj.dragable = True
				'its a programme of the player, so set it to the coords of the suitcase
				If locObj.owner = Game.playerID
					If locObj.StartPosBackup = Null Then Print "StartPosBackup missing";locObj.StartPosBackup = TPosition.Create(0,0)
					If locObj.StartPosBackup.y = 0 Then locObj.StartPosBackup.SetPos(locObj.StartPos)
					locObj.SetCoords(550+imgWidth*localslot, 267, 550+imgWidth*localslot, 267)
					locObj.dragable = True
					localslot:+1
				End If
			EndIf
		Next

		ReverseList TMovieAgencyBlocks.list 					'reorder: first are dragged obj then not dragged

		For Local locObj:TMovieAgencyBlocks = EachIn TMovieAgencyBlocks.List
			If locObj.Programme <> Null
				'which kind of block is the player keeping dragged?
			    If locObj.dragged
					If locObj.owner = game.playerID	Then TMovieAgencyBlocks.HoldingType = 1
					If locObj.owner <= 0			Then TMovieAgencyBlocks.HoldingType = 2
			    End If
				'block is dragable and from movieagency or player
				If DraggingAllowed And locObj.dragable And (locObj.owner <= 0 Or locObj.owner = Game.playerID)
					'if right mbutton clicked and block dragged: reset coord of block
					If MOUSEMANAGER.IsHit(2) And locObj.dragged
						locObj.SetCoords(locObj.StartPos.x, locObj.StartPos.y)
						locObj.dragged = False
						MOUSEMANAGER.resetKey(2)
					EndIf

					'if left mbutton clicked: sell, buy, drag, drop, replace with underlaying block...
					If MouseManager.IsHit(1)
						'search for underlaying block (we have a block dragged already)
						If locObj.dragged
							'obj over employee - so buy or sell
							If functions.IsIn(MouseX(), MouseY(), 20,65, 135, 225)
                          		If locObj.StartPos.y <= 240 And locObj.owner <> Game.playerID Then locObj.Buy()
                          		If locObj.StartPos.y >  240 And locObj.owner =  Game.playerID Then locObj.Sell(1)
								locObj.dragged = False
							EndIf
							'obj over suitcase - so buy ?
							If functions.IsIn(MouseX(),MouseY(),540,250,190,360)
                          		If locObj.StartPos.y <= 240 And locObj.Pos.y > 240  And locObj.owner <> Game.playerID Then locObj.Buy()
								locObj.dragged = False
							EndIf
							'obj over old position in shelf - so sell ?
							If functions.IsIn(MouseX(),MouseY(),locobj.StartPosBackup.x,locobj.StartPosBackup.y,locobj.width,locobj.height)
                          		If locObj.StartPos.y >  240 And locObj.owner =  Game.playerID Then locObj.Sell()
								locObj.dragged = False
							EndIf

							'block over rect of programme-shelf
							If functions.IsIn(locObj.Pos.x, locObj.Pos.y, 590,30, 190,280)
								'want to drop in origin-position
								If locObj.ContainingCoord(MouseX(), MouseY())
									locObj.dragged = False
									MouseManager.resetKey(1)
									If Self.DebugMode=1 Then Print "movieagency: dropped to original position"
								'not dropping on origin: search for other underlaying obj
								Else
									For Local OtherLocObj:TMovieAgencyBlocks = EachIn TMovieAgencyBlocks.List
										If OtherLocObj <> Null
											If OtherLocObj.ContainingCoord(MouseX(), MouseY()) And OtherLocObj <> locObj And OtherLocObj.dragged = False And OtherLocObj.dragable
												If locObj.Programme.isMovie = OtherLocObj.Programme.isMovie
													If game.networkgame Then
														Network.SendMovieAgencyChange(Network.NET_SWITCH, Game.playerID, OtherlocObj.Programme.pid, - 1, locObj.Programme)
					  								End If
													locObj.SwitchBlock(otherLocObj)
													If Self.DebugMode=1 Then Print "movieagency: switched - other obj found"
													Exit	'exit enclosing for-loop (stop searching for other underlaying blocks)
												EndIf
												MouseManager.resetKey(1)
											EndIf
										End If
									Next
								EndIf	'end: drop in origin or search for other obj underlaying
							EndIf 		'end: block over programme-shelf
						Else			'end: an obj is dragged
							If LocObj.ContainingCoord(MouseX(), MouseY())
								locObj.dragged = 1
								MouseManager.resetKey(1)
							EndIf
						EndIf
					EndIf 				'end: left mbutton clicked
				EndIf					'end: dragable block and player or movieagency is owner
			EndIf 						'end: obj.programme <> NULL

			'if obj dragged then coords to mousecursor+displacement, else to startcoords
			If locObj.dragged = 1
				TMovieAgencyBlocks.AdditionallyDragged :+1
				Local displacement:Int = TMovieAgencyBlocks.AdditionallyDragged *5
				locObj.setCoords(MouseX() - locObj.width/2 - displacement, MouseY() - locObj.height/2 - displacement)
			Else
				locObj.SetCoords(locObj.StartPos.x, locObj.StartPos.y)
			EndIf
		Next
		ReverseList TMovieAgencyBlocks.list 'reorder: first are not dragged obj
  End Function
End Type

'Programmeblocks used in Archive
Type TArchiveProgrammeBlocks Extends TBlock
  Field Programme:TProgramme
  Field slot:Int = 0 {saveload = "normal"}
  Field alreadyInSuitcase:Byte=0
  Field owner:Int = 0 {saveload = "normal"}
  Field uniqueID:Int = 0 {saveload = "normal"}
  Field Link:TLink
  Global LastUniqueID:Int =0
  Global DragAndDropList:TList = CreateList()
  Global List:TList = CreateList()
  Global AdditionallyDragged:Int =0


  Function LoadAll(loadfile:TStream)
    TArchiveProgrammeBlocks.List.Clear()
	TArchiveProgrammeBlocks.DragAndDropList.Clear()
    Local BeginPos:Int = Stream_SeekString("<ARCHIVEDND/>",loadfile)+1
    Local EndPos:Int = Stream_SeekString("</ARCHIVEDND>",loadfile)  -13
    loadfile.Seek(BeginPos)
	Local DNDCount:Int = ReadInt(loadfile)
    For Local i:Int = 1 To DNDCount
	  Local DragAndDrop:TDragAndDrop = New TDragAndDrop
      DragAndDrop.slot = ReadInt(loadfile)
      DragAndDrop.used = ReadInt(loadfile)
	  DragAndDrop.used = 0
      DragAndDrop.rectx = ReadInt(loadfile)
      DragAndDrop.recty = ReadInt(loadfile)
      DragAndDrop.rectw = ReadInt(loadfile)
      DragAndDrop.recth = ReadInt(loadfile)
	  DragAndDrop.typ = ""
	  'Print "loaded DND: used"+DragAndDrop.used+" x"+DragAndDrop.rectx+" y"+DragAndDrop.recty+" w"+DragAndDrop.rectw
	  ReadString(loadfile,5) 'finishing string (eg. "|DND|")
      If Not TArchiveProgrammeBlocks.DragAndDropList Then TArchiveProgrammeBlocks.DragAndDropList = CreateList()
      TArchiveProgrammeBlocks.DragAndDropList.AddLast(DragAndDrop)
    Next
    SortList TArchiveProgrammeBlocks.DragAndDropList

    BeginPos:Int = Stream_SeekString("<ARCHIVEB/>",loadfile)+1
    EndPos:Int = Stream_SeekString("</ARCHIVEB>",loadfile)  -11
    loadfile.Seek(BeginPos)
    TArchiveProgrammeBlocks.AdditionallyDragged:Int = ReadInt(loadfile)
	Local ArchiveProgrammeBlocksCount:Int = ReadInt(loadfile)
	If ArchiveProgrammeBlocksCount > 0
	Repeat
      Local ArchiveProgrammeBlocks:TArchiveProgrammeBlocks = New TArchiveProgrammeBlocks
	  ArchiveProgrammeBlocks.uniqueID = ReadInt(loadfile)
	  ArchiveProgrammeBlocks.Pos.Load(Null)
	  ArchiveProgrammeBlocks.OrigPos.Load(Null)
	  Local ProgrammeID:Int  = ReadInt(loadfile)
	  If ProgrammeID >= 0
	    ArchiveProgrammeBlocks.Programme = TProgramme.GetProgramme(ProgrammeID)
        Local targetgroup:Int = ArchiveProgrammeBlocks.Programme.Genre
        If targetgroup > 3 Or targetgroup <0 Then targetgroup = 0
 	    ArchiveProgrammeBlocks.width  = Assets.GetSprite("gfx_movie0").w-1
 	    ArchiveProgrammeBlocks.height = Assets.GetSprite("gfx_movie0").h
	  EndIf
	  ArchiveProgrammeBlocks.dragable= ReadInt(loadfile)
	  ArchiveProgrammeBlocks.dragged = ReadInt(loadfile)
	  ArchiveProgrammeBlocks.slot	= ReadInt(loadfile)
	  ArchiveProgrammeBlocks.StartPos.Load(Null)
	  ArchiveProgrammeBlocks.owner   = ReadInt(loadfile)
	  ArchiveProgrammeBlocks.Link = TArchiveProgrammeBlocks.List.AddLast(ArchiveProgrammeBlocks)

	  ReadString(loadfile,5) 'finishing string (eg. "|PRB|")
	Until loadfile.Pos() >= EndPos
	EndIf
	Print "loaded archiveprogrammeblocks"
  End Function

	Function SaveAll()
		Local ArchiveProgrammeBlocksCount:Int = 0
		LoadSaveFile.xmlBeginNode("ARCHIVEDND")
			'SaveFile.WriteInt(TArchiveProgrammeBlocks.DragAndDropList.Count())
			For Local DragAndDrop:TDragAndDrop = EachIn TArchiveProgrammeBlocks.DragAndDropList
				LoadSaveFile.xmlBeginNode("DND")
					LoadSaveFile.xmlWrite("SLOT",		DragAndDrop.slot)
					LoadSaveFile.xmlWrite("USED",		DragAndDrop.used)
					LoadSaveFile.xmlWrite("RECTX",		DragAndDrop.rectx)
					LoadSaveFile.xmlWrite("RECTY",		DragAndDrop.recty)
					LoadSaveFile.xmlWrite("RECTW",		DragAndDrop.rectw)
					LoadSaveFile.xmlWrite("RECTH",		DragAndDrop.recth)
				LoadSaveFile.xmlCloseNode()
			Next
		LoadSaveFile.xmlCloseNode()
		LoadSaveFile.xmlBeginNode("ALLARCHIVEPROGRAMMEBLOCKS")
			LoadSaveFile.xmlWrite("ADDITIONALLYDRAGGED", 	TArchiveProgrammeBlocks.AdditionallyDragged)
			For Local ArchiveProgrammeBlocks:TArchiveProgrammeBlocks= EachIn TArchiveProgrammeBlocks.List
				If ArchiveProgrammeBlocks <> Null
					'If ArchiveProgrammeBlocks.owner <= 0 Then
					ArchiveProgrammeBlocksCount:+1
				EndIf
			Next
			LoadSaveFile.xmlWrite("ARCHIVEPROGRAMMEBLOCKSCOUNT", 	ArchiveProgrammeBlocksCount)
			For Local ArchiveProgrammeBlocks:TArchiveProgrammeBlocks= EachIn TArchiveProgrammeBlocks.List
				If ArchiveProgrammeBlocks <> Null Then ArchiveProgrammeBlocks.Save()
			Next
		LoadSaveFile.xmlCloseNode()
	End Function

	Method Save()
  		LoadSaveFile.xmlBeginNode("ARCHIVEPROGRAMMEBLOCK")
			Local typ:TTypeId = TTypeId.ForObject(Self)
			For Local t:TField = EachIn typ.EnumFields()
				If t.MetaData("saveload") = "normal" Or t.MetaData("saveload") = "normalExt"
					LoadSaveFile.xmlWrite(Upper(t.name()), String(t.Get(Self)))
				EndIf
			Next
			If Self.Programme <> Null
				LoadSaveFile.xmlWrite("PROGRAMMEID", Self.programme.pid)
			Else
				LoadSaveFile.xmlWrite("PROGRAMMEID",	"-1")
			EndIf
		LoadSaveFile.xmlCloseNode()
	End Method

  'deletes Programmes from Plan (every instance) and from the players collection
  Function ProgrammeToSuitcase:Int(playerID:Int)
   Local myslot:Int=0
  ' SortList(TArchiveProgrammeBlocks.List)
   	For Local locObject:TArchiveProgrammeBlocks = EachIn TArchiveProgrammeBlocks.List
     If locobject.owner = playerID And Not locobject.alreadyInSuitcase
       TMovieAgencyBlocks.Create(locobject.Programme, myslot, playerID)
       If game.networkgame Then If network.IsConnected Then Network.SendProgrammeCollectionChange(playerID, locobject.programme, 1) 'remove all instances
       If Player[playerID].ProgrammePlan.GetActualProgramme().pid = locobject.Programme.pid
		 Player[playerID].audience = 0
       End If
	   Player[playerID].ProgrammePlan.RemoveAllProgrammeInstances( locobject.Programme )
	   locobject.alreadyInSuitcase = True
	   myslot:+1
     EndIf
    Next
  End Function

  Function ClearSuitcase:Int(playerID:Int)
	For Local block:TArchiveProgrammeBlocks=EachIn TArchiveProgrammeBlocks.list
		If block.owner = playerID Then TArchiveProgrammeBlocks.List.Remove(block)
	Next
  End Function

  'if a archiveprogrammeblock is "deleted", the programme is readded to the players programmecollection
  'afterwards it deletes the archiveprogrammeblock
  Method ReAddProgramme:Int(playerID:Int)
	If Self.Programme.isMovie
 	  Player[playerID].ProgrammeCollection.AddMovie(Self.Programme,playerID)
	Else
 	  Player[playerID].ProgrammeCollection.AddSerie(Self.Programme,playerID)
	EndIf
	'remove blocks which may be already created for having left the archive before re-adding it...
    TMovieAgencyBlocks.RemoveBlockByProgramme(Self.Programme, playerID)

	If game.networkgame Then If network.IsConnected Then Network.SendProgrammeCollectionChange(playerID, Self.programme, 2) 'readd

	Self.alreadyInSuitcase = False
	List.Remove(Self)
  End Method

  Method RemoveProgramme:Int(programme:TProgramme, owner:Int=0)
	If game.networkgame Then If network.IsConnected Then Network.SendProgrammeCollectionChange(owner, programme, 3) 'remove from collection
    Player[owner].ProgrammeCollection.RemoveProgramme(programme, owner)
  End Method

  'if owner = 0 then its a block of the adagency, otherwise it's one of the player'
  Function Create:TArchiveProgrammeBlocks(Programme:TProgramme, slot:Int=0, owner:Int=0)
	  Local LocObject:TArchiveProgrammeBlocks=New TArchiveProgrammeBlocks
      Local x:Int=0
      Local y:Int=0
      x=60+slot*15 'ImageWidth(gfx_movie[0])
      y=285 'ImageHeight(gfx_movie[0])
	  LocObject.Pos		= TPosition.Create(x, y)
	  LocObject.OrigPos	= TPosition.Create(x, y)
	  LocObject.StartPos= TPosition.Create(x, y)
 	  LocObject.slot = slot
 	  locObject.owner = owner
 	  LocObject.dragable = 1
      Local targetgroup:Int = Programme.Genre
      If targetgroup > 3 Or targetgroup <0 Then targetgroup = 0
 	  LocObject.width  = Assets.GetSprite("gfx_movie0").w
 	  LocObject.height = Assets.GetSprite("gfx_movie0").h
 	  LocObject.Programme = Programme
 	  If Not List Then List = CreateList()
 	  List.AddLast(LocObject)
 	  SortList List
 	  Return LocObject
	End Function

  'creates a programmeblock which is already dragged (used by movie/series-selection)
    'erstellt einen gedraggten Programmblock (genutzt von der Film- und Serienauswahl)
	Function CreateDragged:TArchiveProgrammeBlocks(movie:TProgramme, owner:Int =-1)
	  Local playerID:Int =0
	  If owner < 0 Then playerID = game.playerID Else playerID = owner
	  Local ProgrammeBlock:TArchiveProgrammeBlocks=New TArchiveProgrammeBlocks
	  ProgrammeBlock.Pos		= TPosition.Create(MouseX(), MouseY())
	  ProgrammeBlock.StartPos	= TPosition.Create(0, 0) 'ProgrammeBlock.x, ProgrammeBlock.y
 	  ProgrammeBlock.owner = playerID
 	  ProgrammeBlock.Programme = Movie
 	  ProgrammeBlock.uniqueID = playerID*10000 +TArchiveProgrammeBlocks.LastUniqueID
 	  TArchiveProgrammeBlocks.LastUniqueID :+1

 	  'hier noch als variablen uebernehmen
 	  ProgrammeBlock.dragable = 1
 	  ProgrammeBlock.width  = Assets.GetSprite("gfx_movie0").w
 	  ProgrammeBlock.height = Assets.GetSprite("gfx_movie0").h
 	  ProgrammeBlock.dragged = 1
 	  TArchiveProgrammeBlocks.AdditionallyDragged :+ 1

 	  If Not List Then List = CreateList()
 	  List.AddLast(ProgrammeBlock)
 	  SortList List
 	  Return ProgrammeBlock
	End Function

'  Method SetDragable(_dragable:Int = 1)
' 	dragable = _dragable
'  End Method

    Method Compare:Int(otherObject:Object)
       Local s:TArchiveProgrammeBlocks = TArchiveProgrammeBlocks(otherObject)
       If Not s Then Return 1                  ' Objekt nicht gefunden, an das Ende der Liste setzen
  '      DebugLog s.title + " "+s.sendtime + " "+sendtime + " "+((dragged * 100 * sendtime + sendtime)-(s.dragged * 100 * s.sendtime + sendtime))
        Return (dragged * 100)-(s.dragged * 100)
    End Method

    Method GetSlotOfBlock:Int()
    	If Pos.x = 589
    	  Return 12+(Int(Floor(StartPos.y - 17) / 30))
    	EndIf
    	If Pos.x = 262
    	  Return 1*(Int(Floor(StartPos.y - 17) / 30))
    	EndIf
    	Return -1
    End Method

    'draw the Block inclusive text
    'zeichnet den Block inklusive Text
    Method Draw()
      SetColor 255,255,255  'normal

      If dragged = 1
    	If TArchiveProgrammeBlocks.AdditionallyDragged > 0 Then SetAlpha 1- 1/TArchiveProgrammeBlocks.AdditionallyDragged * 0.25
       	If Programme.Genre < 9
			Assets.GetSprite("gfx_movie"+Programme.Genre).Draw(Pos.x+7, Pos.y)
     	Else
			Assets.GetSprite("gfx_movie0").Draw(Pos.x+7, Pos.y)
     	EndIf
      Else
        If Pos.x > 520
            If dragable = 0 Then SetAlpha 0.5;SetColor 200,200,200
        EndIf
       	If Programme.Genre < 9
			Assets.GetSprite("gfx_movie"+Programme.Genre).Draw(Pos.x, Pos.y)
     	Else
			Assets.GetSprite("gfx_movie0").Draw(Pos.x, Pos.y)
     	EndIf
      EndIf
      SetColor 255,255,255
      SetAlpha 1
    End Method


  Function DrawAll(DraggingAllowed:Byte)
      SortList TArchiveProgrammeBlocks.List
      For Local locObject:TArchiveProgrammeBlocks = EachIn TArchiveProgrammeBlocks.List
        If locobject.owner <= 0 Or locobject.owner = Game.playerID
   	      locObject.Draw()
        EndIf
      Next
  End Function

    Function UpdateAll(DraggingAllowed:Byte)
      Local number:Int = 0
      Local localslot:Int = 0 'slot in suitcase

      SortList TArchiveProgrammeBlocks.List
      For Local locObject:TArchiveProgrammeBlocks = EachIn TArchiveProgrammeBlocks.List
      If DraggingAllowed And locobject.owner <= 0 Or locobject.owner = Game.playerID
        number :+ 1
        If MOUSEMANAGER.IsHit(2) And locObject.dragged = 1
		  locObject.ReAddProgramme(game.playerID)
          MOUSEMANAGER.resetKey(2)
		  Exit
        EndIf

        If MOUSEMANAGER.IsHit(1)
          If locObject.dragged = 0 And locObject.dragable = 1
            If functions.IsIn(MouseX(), MouseY(), locObject.Pos.x, locobject.Pos.y, locObject.width, locObject.height)
              locObject.dragged = 1
            EndIf
          Else If locobject.dragable = 1
            Local realDNDfound:Int = 0
            If MOUSEMANAGER.IsHit(1)
              locObject.dragged = 0
              realDNDfound = 0
              For Local DragAndDrop:TDragAndDrop = EachIn TArchiveProgrammeBlocks.DragAndDropList
               'don't allow dragging of series into the agencies movie-row and wise versa
                If DragAndDrop.CanDrop(MouseX(),MouseY(), "archiveprogrammeblock") = 1 And (DragAndDrop.rectx < 50+200 Or DragAndDrop.rectx > 50+Assets.GetSprite("gfx_movie0").w*(localslot-1))
                  For Local OtherlocObject:TArchiveProgrammeBlocks= EachIn TArchiveProgrammeBlocks.List
                   If DraggingAllowed And otherlocobject.owner <= 0 'on plan and not in elevator
                     'is there a NewsBlock positioned at the desired place?
                      If MOUSEMANAGER.IsHit(1) And OtherlocObject.dragable = 1 And OtherlocObject.Pos.x = DragAndDrop.rectx And OtherlocObject.Pos.y = DragAndDrop.recty
                         OtherlocObject.dragged = 1
           	         EndIf
                   EndIf
                  Next
				  	LocObject.Pos.SetXY(DragAndDrop.rectx, DragAndDrop.recty)
					locobject.RemoveProgramme(locobject.Programme, locobject.owner)
					LocObject.StartPos.SetPos(LocObject.Pos)
                    realDNDfound =1
                    Exit 'exit loop-each-dragndrop, we've already found the right position
                EndIf
              Next
              'suitcase as dndzone
              If Not realDNDfound And functions.IsIn(MouseX(),MouseY(),50-10,280-20,200+2*10,100+2*20)
              	For Local DragAndDrop:TDragAndDrop = EachIn TArchiveProgrammeBlocks.DragAndDropList
              		If functions.IsIn(DragAndDrop.rectx, DragAndDrop.recty, 50,280,200,100)
              		  If DragAndDrop.rectx >= 55 + gfx_contract.GetSprite("Contract0").w * (localslot)
              		  If DragAndDrop.used = 0 'and DragAndDrop.slot > (localslot) Then
              		    DragAndDrop.used =1
						LocObject.Pos.SetXY(DragAndDrop.rectx, DragAndDrop.recty)
						LocObject.StartPos.SetPos(LocObject.Pos)
                        Exit 'exit loop-each-dragndrop, we've already found the right position
              		  End If
              		  EndIf
                	End If
              	Next
              End If
              'no drop-area under Adblock (otherwise this part is not executed - "exit"), so reset position
              If Abs(locObject.Pos.x - locObject.StartPos.x)<=1 And..
                 Abs(locObject.Pos.y - locObject.StartPos.y)<=1
      		    locObject.dragged    = 0
				LocObject.Pos.SetPos(LocObject.StartPos)
  				SortList TArchiveProgrammeBlocks.List
              EndIf
            EndIf
          EndIf
         EndIf

        If locObject.dragged = 1
          TArchiveProgrammeBlocks.AdditionallyDragged :+1
		  LocObject.Pos.SetXY(MouseX() - locObject.width /2 - TArchiveProgrammeBlocks.AdditionallyDragged *5,..
							  MouseY() - locObject.height /2 - TArchiveProgrammeBlocks.AdditionallyDragged *5)
        EndIf
        If locObject.dragged = 0
          If locObject.StartPos.x = 0 And locObject.StartPos.y = 0
          	locObject.dragged = 1
          	TArchiveProgrammeBlocks.AdditionallyDragged:+ 1
          Else
		  	LocObject.Pos.SetPos(LocObject.StartPos)
	      EndIf
        EndIf
      EndIf
      locobject.dragable = 1
      Next
        TArchiveProgrammeBlocks.AdditionallyDragged = 0
  End Function

End Type

'Programmeblocks used in Archive
Type TAuctionProgrammeBlocks
  Field x:Int = 0 {saveload = "normal"}
  Field y:Int = 0 {saveload = "normal"}
  Field imageWithText:TImage = Null
  Field Programme:TProgramme
  Field slot:Int = 0 {saveload = "normal"}
  Field Bid:Int[5]
  Field uniqueID:Int = 0 {saveload = "normal"}
  Field Link:TLink
  Global LastUniqueID:Int =0
  Global List:TList = CreateList()
  Global DrawnFirstTime:Byte = 0

  Function ProgrammeToPlayer()
    For Local locObject:TAuctionProgrammeBlocks = EachIn TAuctionProgrammeBlocks.List
      If locObject.Programme <> Null And locObject.Bid[0] > 0 And locObject.Bid[0] <= 4
	    Player[locobject.Bid[0]].ProgrammeCollection.AddProgramme(locobject.Programme,locObject.Bid[0])
		Print "player "+Player[locobject.Bid[0]].name + " won the auction for: "+locobject.Programme.title
		Repeat
		  LocObject.Programme = TProgramme.GetRandomMovieWithMinPrice(250000)
		Until LocObject.Programme <> Null
		locObject.imageWithText = Null
		For Local i:Int = 0 To 4
	 	  LocObject.Bid[i] = 0
		Next
      End If
    Next

  End Function

  Function LoadAll(loadfile:TStream)
    TAuctionProgrammeBlocks.List.Clear()
	Print "cleared auctionblocks:"+TAuctionProgrammeBlocks.List.Count()
    Local BeginPos:Int = Stream_SeekString("<ARCHIVEB/>",loadfile)+1
    Local EndPos:Int = Stream_SeekString("</AUCTIONB>",loadfile)  -11
    loadfile.Seek(BeginPos)
	Local AuctionProgrammeBlocksCount:Int = ReadInt(loadfile)
	If AuctionProgrammeBlocksCount > 0
	Repeat
      Local AuctionProgrammeBlocks:TAuctionProgrammeBlocks = New TAuctionProgrammeBlocks
	  AuctionProgrammeBlocks.uniqueID = ReadInt(loadfile)
	  AuctionProgrammeBlocks.x 	= ReadInt(loadfile)
	  AuctionProgrammeBlocks.y   = ReadInt(loadfile)
	  Local ProgrammeID:Int  = ReadInt(loadfile)
	  If ProgrammeID >= 0
	    AuctionProgrammeBlocks.Programme = TProgramme.GetProgramme(ProgrammeID)
	  EndIf
	  AuctionProgrammeBlocks.slot	= ReadInt(loadfile)
	  AuctionProgrammeBlocks.Bid[0]	= ReadInt(loadfile)
	  AuctionProgrammeBlocks.Bid[1] = ReadInt(loadfile)
	  AuctionProgrammeBlocks.Bid[2] = ReadInt(loadfile)
	  AuctionProgrammeBlocks.Bid[3] = ReadInt(loadfile)
	  AuctionProgrammeBlocks.Bid[4] = ReadInt(loadfile)
	  AuctionProgrammeBlocks.Link   = TAuctionProgrammeBlocks.List.AddLast(AuctionProgrammeBlocks)

	  ReadString(loadfile,5) 'finishing string (eg. "|PRB|")
	Until loadfile.Pos() >= EndPos
	EndIf
	Print "loaded auctionprogrammeblocks"
  End Function

	Function SaveAll()
	    Local AuctionProgrammeBlocksCount:Int = 0
		For Local AuctionProgrammeBlocks:TAuctionProgrammeBlocks= EachIn TAuctionProgrammeBlocks.List
			If AuctionProgrammeBlocks <> Null Then AuctionProgrammeBlocksCount:+1
		Next
		LoadSaveFile.xmlBeginNode("ALLAUCTIONPROGRAMMEBLOCKS")
			LoadSaveFile.xmlWrite("AUCTIONPROGRAMMEBLOCKSCOUNT",	AuctionProgrammeBlocksCount)
			For Local AuctionProgrammeBlocks:TAuctionProgrammeBlocks= EachIn TAuctionProgrammeBlocks.List
				If AuctionProgrammeBlocks <> Null Then AuctionProgrammeBlocks.Save()
			Next
		LoadSaveFile.xmlCloseNode()
	End Function

	Method Save()
		LoadSaveFile.xmlBeginNode("CONTRACTBLOCK")
			Local typ:TTypeId = TTypeId.ForObject(Self)
			For Local t:TField = EachIn typ.EnumFields()
				If t.MetaData("saveload") = "normal" Or t.MetaData("saveload") = "normalExt"
					LoadSaveFile.xmlWrite(Upper(t.name()), String(t.Get(Self)))
				EndIf
			Next
			If Self.Programme <> Null
				LoadSaveFile.xmlWrite("PROGRAMMEID",	Self.programme.pid)
			Else
				LoadSaveFile.xmlWrite("PROGRAMMEID", "-1")
			EndIf
			LoadSaveFile.xmlWrite("BID0", Self.Bid[0] )
			LoadSaveFile.xmlWrite("BID1", Self.Bid[1] )
			LoadSaveFile.xmlWrite("BID2", Self.Bid[2] )
			LoadSaveFile.xmlWrite("BID3", Self.Bid[3] )
			LoadSaveFile.xmlWrite("BID4", Self.Bid[4] )
		LoadSaveFile.xmlCloseNode()
	End Method

  Function Create:TAuctionProgrammeBlocks(Programme:TProgramme, slot:Int=0)
	  Local LocObject:TAuctionProgrammeBlocks=New TAuctionProgrammeBlocks
      Local x:Int=0
      Local y:Int=0
	  x = 140+((slot+1) Mod 2)* 260
	  y = 75+ Ceil((slot-1) / 2)*60
 	  LocObject.x = x
 	  LocObject.y = y
	  LocObject.Bid[0] = 0
	  LocObject.Bid[1] = 0
	  LocObject.Bid[2] = 0
	  LocObject.Bid[3] = 0
	  LocObject.Bid[4] = 0
 	  LocObject.slot = slot
 	  LocObject.Programme = Programme
 	  If Not List Then List = CreateList()
 	  List.AddLast(LocObject)
 	  SortList List
 	  Return LocObject
	End Function

  Method Compare:Int(otherObject:Object)
       Local s:TArchiveProgrammeBlocks = TArchiveProgrammeBlocks(otherObject)
       If Not s Then Return 1                  ' Objekt nicht gefunden, an das Ende der Liste setzen
  '      DebugLog s.title + " "+s.sendtime + " "+sendtime + " "+((dragged * 100 * sendtime + sendtime)-(s.dragged * 100 * s.sendtime + sendtime))
        Return (slot)-(s.slot)
    End Method

    'draw the Block inclusive text
    'zeichnet den Block inklusive Text
    Method Draw()

	  Local HighestBidder:String = ""
	  Local HighestBid:Int = Programme.ComputePrice()
	  Local NextBid:Int = 0
	  If Bid[0]>0 And Bid[0] <=4 Then If Bid[ Bid[0] ] <> 0 Then HighestBid = Bid[ Bid[0] ]
	  NextBid = HighestBid
      If HighestBid < 100000
	    NextBid :+ 10000
	  Else If HighestBid >= 100000 And HighestBid < 250000
	    NextBid :+ 25000
	  Else If HighestBid >= 250000 And HighestBid < 750000
	    NextBid :+ 50000
	  Else If HighestBid >= 750000
	    NextBid :+ 75000
	  EndIf

	  SetColor 255,255,255  'normal
	    If imagewithtext <> Null And Self.DrawnFirstTime > 20
	      DrawImage(imagewithtext,x,y)
	    Else
		  If Self.DrawnFirstTime < 30 Then Self.DrawnFirstTime:+1
		  Assets.GetSprite("gfx_auctionmovie").Draw(x,y)
	      FontManager.baseFont.drawBlock(Programme.title, x+31,y+5, 215,20)
	      FontManager.baseFont.drawBlock("Preis:"+HighestBid+"€", x+31,y+20, 215,20,2,Null, 100,100,100,1)
	      FontManager.baseFont.drawBlock("Bieten:"+NextBid+"€", x+31,y+33, 215,20,2,Null, 0,0,0,1)
          If Player[Bid[0]] <> Null
    	    HighestBidder = Player[Bid[0]].name
	        Local colr:Int = Player[Bid[0]].color.colr'+900
	        Local colg:Int = Player[Bid[0]].color.colg'+900
	        Local colb:Int = Player[Bid[0]].color.colb'+900
		    If colr > 255 Then colr = 255
		    If colg > 255 Then colg = 255
		    If colb > 255 Then colb = 255
'			SetImageFont FontManager.GW_GetFont("Default", 10)
			SetAlpha 1.0;FontManager.GetFont("Default", 10).drawBlock(HighestBidder, x + 33, y + 35, 150, 20, 0, colr - 200, colg - 200, colb - 200, 1)
			SetAlpha 1.0;FontManager.GetFont("Default", 10).drawBlock(HighestBidder, x + 32, y + 34, 150, 20, 0, colr - 150, colg - 150, colb - 150, 1)
	        Local pixmap:TPixmap = GrabPixmap(x+33-2,y+35-2,TextWidth(HighestBidder)+4,TextHeight(HighestBidder)+3)
			pixmap = ConvertPixmap(pixmap, PF_RGBA8888)
            blurPixmap(pixmap, 0.6)
			DrawPixmap(YFlipPixmap(pixmap), x+33-2,y+35-2 + pixmap.height)
			SetAlpha 1.0;FontManager.GetFont("Default", 10).drawBlock(HighestBidder, x + 32, y + 34, 150, 20, 0, colr, colg, colb, 1)
		  EndIf
		  Imagewithtext = TImage.Create(Assets.GetSprite("gfx_auctionmovie").w,Assets.GetSprite("gfx_auctionmovie").h-1,1,0,255,0,255)
		  Imagewithtext.pixmaps[0] = GrabPixmap(x,y,Assets.GetSprite("gfx_auctionmovie").w,Assets.GetSprite("gfx_auctionmovie").h-1)
	    EndIf
	  SetColor 255,255,255
      SetAlpha 1
    End Method


  Function DrawAll(DraggingAllowed:Byte)
      SortList TAuctionProgrammeBlocks.List
      For Local locObject:TAuctionProgrammeBlocks = EachIn TAuctionProgrammeBlocks.List
        locObject.Draw()
      Next
  End Function

	Method SetBid(playerID:Int, price:Int)
		If Player[playerID].finances[TFinancials.GetDayArray(Game.day)].PayProgrammeBid(price) = True
			If Player[Self.Bid[0]] <> Null Then
				Player[Self.Bid[0]].finances[TFinancials.GetDayArray(game.day)].GetProgrammeBid(Self.Bid[Self.Bid[0]])
				Self.Bid[Self.Bid[0]] = 0
			EndIf
			Self.Bid[0] = playerID
			Self.Bid[playerID] = price
			Self.imageWithText = Null
		EndIf
	End Method

	Function UpdateAll(DraggingAllowed:Byte)
		SortList TAuctionProgrammeBlocks.List
		local mouseHit:int = MOUSEMANAGER.IsHit(1)
		For Local locObject:TAuctionProgrammeBlocks = EachIn TAuctionProgrammeBlocks.List
			If mouseHit and functions.IsIn(MouseX(), MouseY(), locObject.x, locObject.y, Assets.GetSprite("gfx_auctionmovie").w, Assets.GetSprite("gfx_auctionmovie").h) AND locObject.Bid[0] <> game.playerID
				Local HighestBid:Int = locObject.Programme.ComputePrice()
				Local NextBid:Int = 0
				If locObject.Bid[0]>0 And locObject.Bid[0] <=4 Then If locObject.Bid[ locObject.Bid[0] ] <> 0 Then HighestBid = locObject.Bid[ locObject.Bid[0] ]
				NextBid = HighestBid
				If HighestBid < 100000
					NextBid :+ 10000
				Else If HighestBid >= 100000 And HighestBid < 250000
					NextBid :+ 25000
				Else If HighestBid >= 250000 And HighestBid < 750000
					NextBid :+ 50000
				Else If HighestBid >= 750000
					NextBid :+ 75000
				EndIf
	  			If game.networkgame Then Network.SendMovieAgencyChange(Network.NET_BID, game.playerID, NextBid, -1, locObject.Programme)
	  			locObject.SetBid(game.playerID, NextBid)  'set the bid
			EndIf
		Next
	End Function

End Type