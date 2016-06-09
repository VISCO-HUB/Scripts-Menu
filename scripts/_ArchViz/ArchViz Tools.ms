/*  
[INFO] 

NAME = ArchViz Tools
VERSION = 1.0.5
AUTHOR = MastaMan
DEV = Visco CG
HELP = 

[1.0.0]

* First release =

[1.0.1]

+ Added: Mask By ObjectID =
+ Added: Buttons for delete Render Elements=
+ Added: Mask By Color=
+ Added: Button Random Object Color=

[1.0.2]

+ Added: Light Select Element=
* Fixed Mask By ObjectID. Now works for instances=

[1.0.3]

+ Added: Ambient Occlusion Elements=

[1.0.4]

+ Added: Support blend materials for MatID

[1.0.5]

+ Added: Change AO when set radius in spinners

[ABOUT]

This script helps to quickly add Render Elements for masks=

[TEST]

Check: Small AO and Large AO dynamically change radius=
@=
Check: Correct saved names render elements=

[SCRIPT]
*/	


fn getScriptInfo s releaseInfo: "" =
(		
	if(releaseInfo != "") do
	(
		r = getINISetting s releaseInfo
		return r
	)
	
	v = getINISetting s "INFO" "VERSION"
	a = getINISetting s "INFO" "AUTHOR"
	n = getINISetting s "INFO" "NAME"
	o = getINISetting s "ABOUT"
	c = getINISetting s "INFO" "DEV"
	h = getINISetting s "INFO" "HELP"
	
	r = for i in (getINISetting s) where i != "ABOUT" and i != "SCRIPT" and i != "COPY" collect i
	
	return #(n, a, v, o, r, c, h)
)

fn parseToLine m = 
(
	if(m.count == 0) do return ""
	
	l = ""				
	for i in m do l += i + "\n"
	return l
)

rollout  _rRenderElement "Render Elements" 
(	
	local sMaterials = #()
	
	group "MultiMatteElements"
	(
		button btnCreateMtlIds "MatID" width: 93 across: 3 offset: [-2, 0] align: #left
		checkbutton btnMtlIdSelected "S" width: 25 offset: [35, 0] tooltip: "Create only for selected objects"
		button btnDelMtlIds "X" width: 25  offset: [15, 0] tooltip: "Delete all MatID Render Elements"
		button btnCreateObjIds "ObjectID" width: 93 across: 3 offset: [-2, 0] align: #left
		button btnAddObjIds "+" width: 25 offset: [35, 0] tooltip: "Add only selected objects"
		button btnDelObjIds "X" width: 25 offset: [15, 0] tooltip: "Delete all ObjectID Render Elements"
	)

	group "VrayWireColor"
	(
		button btnWireColor "Mask by Color" width: 117 across: 2 offset: [6, 0]		
		button btnDelWireColor "X" width: 25  offset: [4, 0] tooltip: "Delete VrayWireColor Render Element" align: #right
		radiobuttons rdoRandomWireColor "Random Object Color:" labels: #("Don't Change", "By Objects", "By Instances") align: #left				
	)
	
	group "VrayLightSelect"
	(		
		button btnLightselect "Light Select" width: 120 across: 2 offset: [-2, 0]
		button btnDelLightSelect "X" width: 25  offset: [27, 0] tooltip: "Delete all LightSelect Render Elements"
	)
	
	group "Ambient Occlusion"
	(
		button btnSmallAO "Small AO" width: 120 across: 2 offset: [48, 0] align: #right
		button btnDelSmallAO "X" width: 25  offset: [4, 0] tooltip: "Delete Small AO Render Element" align: #right
		spinner spnSmallAO "Small AO Radius: " range: [0, 99999, 150]fieldWidth: 50 type: #worldunits align: #right
		
		button btnLargeAO "Large AO" width: 120 across: 2 offset: [48, 0] align: #right
		button btnDelLargeAO "X" width: 25  offset: [4, 0] tooltip: "Delete Large AO Render Element" align: #right
		spinner spnLargeAO "Large AO Radius: " range: [0, 99999, 400] fieldWidth: 50 type: #worldunits align: #right
	)
	
	fn isVray =
	(
		_Vray = renderers.current
		if(matchPattern (_Vray as string) pattern:"V_Ray_Adv*") do return true
		return false
	)

	
	fn appendMaterial m = 
	(	
		if(findItem sMaterials m == 0 and classOf m == VRayMtl) do append sMaterials m 
		if(classOf m == VRayBlendMtl and  classOf m.baseMtl == VRayMtl and findItem sMaterials m.baseMtl == 0) do append sMaterials m.baseMtl
		if(classOf m == Blend and  classOf m.map1 == VRayMtl and findItem sMaterials m.map1 == 0) do append sMaterials m.map1
	)
	
	fn existElement el =
	(
		re = maxOps.GetCurRenderElementMgr()
		n = re.NumRenderElements()
		
		for i in 0 to n where (re.GetRenderElement i) != undefined and (MatchPattern (re.GetRenderElement i).elementName pattern: el) do return true
		
		return false
	)
	
	fn removeElemet re n el = 
	(	
		for i in 0 to n - 1 where (re.GetRenderElement i) != undefined and (MatchPattern (re.GetRenderElement i).elementName pattern: el) do re.RemoveRenderElement (re.GetRenderElement i)	
	)
	
	fn deleteElements el =
	(			
		re = maxOps.GetCurRenderElementMgr()
		n = re.NumRenderElements()
		
		for i in 1 to n do removeElemet re n el				
			
		renderSceneDialog.open()
	)
	
	fn findElement n =
	(
		re = maxOps.GetCurRenderElementMgr()
		c = re.NumRenderElements()
		
		el = #()
		for i in 0 to c - 1 where (re.GetRenderElement i) != undefined and (MatchPattern (re.GetRenderElement i).elementName pattern: n) do append el (re.GetRenderElement i)
		
		return el
	)
	
	fn addElement el n =
	(		
		el.elementName = n
		re = maxOps.GetCurRenderElementMgr()				
		re.AddRenderElement el	
					
		renderSceneDialog.open()
	)
	
	fn getInstances o =
	(	
		sceneInst = #()
				 
		for i in o do 
		(	
			InstanceMgr.GetInstances i &tmpInst
			
			doAppend = false
			for ii in sceneInst where findItem ii i != 0 do doAppend = true
			
			if(doAppend == false) do append sceneInst tmpInst
		)
		
		return sceneInst
	)
	
	fn resetMatId = 
	(
		for i in sceneMaterials where i != undefined do 
		(							
			if(classOf i == Multimaterial) do
			(
				for ii in i do 
				(	
					try(ii.override_effect_id = off)catch()
					try(ii.effect_id = 0)catch()
				)
				
				continue
			)
			
			try(i.override_effect_id = off)catch()
			try(i.effect_id = 0)catch()
		)
	)
	
	fn resetObjectID = for i in geometry do i.gbufferchannel = 0
	
	fn randomWireColor =
	(
		case (rdoRandomWireColor.state) of
		(
			2: for i in geometry do i.wirecolor = random black white
			3:
			(
				g = getInstances geometry
				
				for i in g where i != undefined do
				(
					c = random black white
					for ii in i do ii.wirecolor = c
				)
			)
		)
	)
	
	fn createObjIds g sel:false =
	(
		prefix = ""
		
		if(sel == true) do prefix = "Sel_"
		
		objById = getInstances g
		
		for i in 1 to objById.count do for c in objById[i] do c.gbufferchannel = i
		
		for i in 1 to objById.count by 3 do
		(
			mme = MultiMatteElement()
			n = prefix + "ObjectID_MultiMatteElement " + i as string + " - " + (i + 2) as string
			mme.MatID = false
			mme.R_gbufID = i
			mme.G_gbufID = i + 1
			mme.B_gbufID = i + 2
				
			addElement mme n
		)
	)
		
	on _rRenderElement open do
	(
		if(isVray() == false) do 
		(
			messageBox "Please assign Vray Render!" title: "Warning!"
			try(closeRolloutFloater  rArchVizTools) catch()
		)
		
		el = findElement "VRayExtraTex_Small AO"
		
		if(el.count > 0 and classOf el[1].texture == VRayDirt) do
		(
			spnSmallAO.value = el[1].texture.radius
		)
		
		el = findElement "VRayExtraTex_Large AO"
		
		if(el.count > 0 and classOf el[1].texture == VRayDirt) do
		(
			spnLargeAO.value = el[1].texture.radius
		)
		
	)
	
	on btnAddObjIds pressed do
	(
		s = selection
		if(s.count == 0) do return messageBox "Please select objects!" title: "Warning!"
		
		deleteElements "ObjectID_*"
		deleteElements "Sel_ObjectID_*"
		
		g1 = #()
		g2 = #()
		
		g1 = for i in geometry where i.gbufferchannel != 0 collect i
		g2 = for i in selection where i.gbufferchannel == 0 collect i
			
		createObjIds (g1 + g2) sel: true
		
	)
	
	on btnDelMtlIds pressed do 
	(	
		deleteElements "MtlID_*"
		deleteElements "Sel_MtlID_*"
		resetMatId()
	)
	on btnDelObjIds pressed do
	(		
		deleteElements "ObjectID_*"
		deleteElements "Sel_ObjectID_*"
		resetObjectID()
	)
	
	on btnDelWireColor pressed do deleteElements "Object Color Mask"
	on btnDelLightSelect pressed do deleteElements "LightSelect_*"
	
	on btnLightselect pressed do
	(
		sceneLights = for i in lights where isKindOf i light collect i

		instanceLights = getInstances sceneLights

		for i in 1 to instanceLights.count do
		(
			vls = VRayLightSelect()
			n = "LightSelect_" + i as string
			vls.lights = instanceLights[i]
				
			addElement vls n
		)
	)
	
	on btnWireColor pressed do
	(
		randomWireColor()
		
		n = "Object Color Mask"		
		if(existElement n == true) do return false
				
		vwc = VrayWireColor()
				
		addElement vwc n
	)
	

	on btnCreateObjIds pressed do
	(
		deleteElements "ObjectID_*"
		deleteElements "Sel_ObjectID_*"
		
		resetObjectID()
		
		createObjIds geometry	
	)
	
	on btnCreateMtlIds pressed do
	(	
		deleteElements "MtlID_*"
		deleteElements "Sel_MtlID_*"
		
		sMaterials = #()
		
		renderSceneDialog.open()
		
		resetMatId()
		
		prefix = ""
		g = #()
		
		case (btnMtlIdSelected.checked) of
		(
			true: 
			(
				g = selection						
				prefix = "Sel_"					
				if(g.count == 0) do MessageBox "Please select objects!" title: "Warning!"
			)
			default: g = geometry
		)
		
		for i in g where i.material != undefined do 
		(	
			m = i.material
			
			if(classOf m == Multimaterial) do
			(
				mm = for ii in m do appendMaterial ii
				
				continue
			)
			
			appendMaterial m	
		)

		
		for i in 1 to sMaterials.count do
		(
			sMaterials[i].override_effect_id = on
			sMaterials[i].effect_id = i	
		)

		for i in 1 to sMaterials.count by 3 do
		(
			mme = MultiMatteElement()
			n = prefix + "MtlID_MultiMatteElement " + i as string + " - " + (i + 2) as string
			mme.MatID = true
			mme.R_gbufID = i
			mme.G_gbufID = i + 1
			mme.B_gbufID = i + 2
				
			addElement mme n
		)
	)
	
	fn getAOname n =
	(
		z = filterString n "_"
		return z[2]
	)
	
	on btnSmallAO pressed do
	(
		n = "VRayExtraTex_Small AO"
		deleteElements n
		
		vet = VRayExtraTex()		
		vet.texture = VrayDirt()
		vet.texture.radius = spnSmallAO.value
		vet.texture.name = getAOname n
		vet.texture.subdivs = 32
			
		addElement vet n
	)
	
	on btnDelSmallAO pressed do deleteElements "VRayExtraTex_Small AO"
		
	on btnLargeAO pressed do
	(
		n = "VRayExtraTex_Large AO"
		deleteElements n
				
		vet = VRayExtraTex()		
		vet.texture = VrayDirt()
		vet.texture.radius = spnLargeAO.value
		vet.texture.name = getAOname n
		vet.texture.subdivs = 32
			
		addElement vet n
	)
	
	on btnDelLargeAO pressed do deleteElements "VRayExtraTex_Large AO"
		
	
	fn changeElementAO n x =
	(
		el = findElement n
		
		if(el.count > 0 and classOf el[1].texture == VRayDirt) then
		(
			el[1].texture.radius = x
			el[1].texture.subdivs = 32
			el[1].elementName = n
		)		
		else
		(					
			vet = VRayExtraTex()		
			vet.texture = VrayDirt()
			vet.texture.radius = x
			vet.texture.subdivs = 32
			vet.texture.name = getAOname n
				
			addElement vet n
		)
	)
	
	on spnSmallAO changed x do
	(
		n = "VRayExtraTex_Small AO"
		
		changeElementAO n x
	)
	
	on spnLargeAO changed x do
	(
		n = "VRayExtraTex_Large AO"
		
		changeElementAO n x				
	)
)


rollout _rAbout "About" 
(
	label lblName "" 
	label lblVer "" 
	
	label lblAuthor "" height: 30
	label lblCopy ""  height: 30
	
	on _rAbout open do
	(		
		i = getScriptInfo (getThisScriptFilename())
			
		lblName.caption = i[1]
		lblAuthor.caption = i[2]
		lblVer.caption = i[3]
		lblCopy.caption = i[6]
	)
)

try(closeRolloutFloater rArchVizTools) catch()
global rArchVizTools = newRolloutFloater "ArchViz" 180 450

addRollout _rRenderElement rArchVizTools rolledUp:false 
addRollout _rAbout rArchVizTools rolledUp:true 


