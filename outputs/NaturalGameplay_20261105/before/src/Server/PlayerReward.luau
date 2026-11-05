-- One server draw and one sanitized visual builder for all roster members.
local Config=require(game.ReplicatedStorage.Shared.Config)
local Templates=game.ServerStorage:WaitForChild("PlayerTemplates")
local Reward={}
local rng=Random.new()
function Reward.Pool(tier)
 local pool={} for _,entry in Config.PlayerRoster do if entry.Tier==tier then table.insert(pool,entry) end end
 assert(#pool>0,"Empty player pool: "..tier)
 return pool
end
function Reward.Pick(tier)
 local pool=Reward.Pool(tier) local total=0
 for _,entry in pool do total+=entry.Weight end
 local roll=rng:NextNumber()*total
 for _,entry in pool do roll-=entry.Weight if roll<0 then return entry end end
 return pool[#pool]
end
function Reward.Attach(card,id)
 local mesh=Templates:FindFirstChild(id):Clone()
 local model=Instance.new("Model") model.Name="PlayerVisual"
 mesh.Name="PlayerMesh"
 local scale=Config.Reveal.DisplayHeight/mesh.Size.Y
 mesh.Size*=scale
 for _,bone in mesh:GetDescendants() do if bone:IsA("Bone") then bone.CFrame=CFrame.new(bone.CFrame.Position*scale)*bone.CFrame.Rotation end end
 mesh.CFrame=card.CFrame mesh.Anchored=false mesh.Massless=true
 mesh.CanCollide=false mesh.CanTouch=false mesh.CanQuery=false
 mesh.Parent=model model.PrimaryPart=mesh
 local weld=Instance.new("WeldConstraint") weld.Part0=card weld.Part1=mesh weld.Parent=mesh
 model:SetAttribute("AnimationClip","RunR6") model:SetAttribute("Moving",false)
 model.Parent=card model:AddTag("AnimatedCharacter")
end
return Reward
