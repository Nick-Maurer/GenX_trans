"""
GenX: An Configurable Capacity Expansion Model
Copyright (C) 2021,  Massachusetts Institute of Technology
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
A complete copy of the GNU General Public License v2 (GPLv2) is available
in LICENSE.txt.  Users uncompressing this from an archive may not have
received this license file.  If not, see <http://www.gnu.org/licenses/>.
"""

@doc raw"""
	retrofit(EP::Model, inputs::Dict)

This function defines the constraints for operation of retrofit technologies, including
	but not limited to carbon capture, natural gas-hydrogen blending, and thermal energy storage.

For retrofittable resources $y$, the sum of retrofit capacity $\Omega_{y_r,z}$ that may be installed
is constrained by the amount of capacity $\Delta_{y,z}$ retired as well as the retrofit efficiency
$ef_{y_r}$ where $y_r$ is any technology in the set of retrofits of $y$ ($RF(y)$).

```math
\begin{aligned}
\sum_{y_r} \frac{\Omega_{y_r,z}}{ef(y_r)} \leq \Delta_{y,z}
\hspace{4 cm}  \forall y \in Y, y_r \in \mathcal{RF(y)}, z \in \mathcal{Z}
\end{aligned}
```
"""
function retrofit(EP::Model, inputs::Dict)

	println("Retrofit Resources Module")

	G = inputs["G"]   # Number of resources (generators, storage, DR, and DERs)
	RETRO = inputs["RETRO"] # Set of all retrofit resources
	NEW_CAP = inputs["NEW_CAP"] # Set of all resources eligible for capacity expansion
	RET_CAP = inputs["RET_CAP"] # Set of all resources eligible for capacity retirements
	RETRO_SOURCES = inputs["RETROFIT_SOURCES"] # Source technologies (Resource Name) for each retrofit [1:G]
	RETRO_SOURCE_IDS = inputs["RETROFIT_SOURCE_IDS"] # Source technologies (ID) for each retrofit [1:G]
	RETRO_EFFICIENCY = inputs["RETROFIT_EFFICIENCIES"] # Ratio of installed retrofit capacity to source capacity [0:1]

	# CONFIRM that this works if techs have New_Build=0 (In addition to 1 and -1 which I believe work as of now)

	println("RETRO SOURCE")
	println(inputs["RETROFIT_SOURCES"])
	println("RETIREMENT-ELIGBLE RESOURCES")
	println(RET_CAP)
	println("EXPANSION-ELIGIBLE RESOURCES")
	println(NEW_CAP)
	println("RETROFIT-ELIGIBLE RESOURCES")
	println(RETRO)
	println("  Intersection: ")
	println([intersect(findall(x->in(inputs["RESOURCES"][y],RETRO_SOURCES[x]),1:G), findall(x->x in NEW_CAP, 1:G)) for y in RET_CAP])

	### Variables ###
	# Retrofit capacity transition variables included in investment_discharge.jl.
	# This will require separate assignment in multi-stage formulation.

	### Constraints ###

	println("Retrofit Installation Constraint...")
	# (Many-to-One) New installed capacity of retrofit technology r must be equal to the (efficiency-downscaled) sum of capacity retrofitted to technology r from source technologies yr
	#@constraint(EP, cRetroInstall[r in RETRO], EP[:vCAP][r] == sum(EP[:vRETROFIT][yr,r]*RETRO_EFFICIENCY[yr,r] for yr in RETRO_SOURCE_ID[r]))   # Optional matrix formulation. Everything is source-dest indexed, but many of those indices mean nothing and might lead to odd behavior if mishandled.
	@constraint(EP, cRetroInstall[r in RETRO], EP[:vCAP][r] == sum(EP[:vRETROFIT][RETRO_SOURCE_IDS[r][i],r]*RETRO_EFFICIENCY[r][i] for i in 1:inputs["NUM_RETROFIT_SOURCES"][r]))   # Smaller, maybe less intuitive list formulation. RE is indexed by retrofit tech index then by source index of that retrofit tech

	println("Retrofit Retirement Constraint...")
	# (One-to-Many) Sum of retrofitted capacity from a given source technology must not exceed the retired capacity of that technology. (Retrofitting is included within retirement, not a distinct category)
	@constraint(EP, cRetroRetire[y in RET_CAP], EP[:vRETCAP][y] >= sum( EP[:vRETROFIT][y,r] for r in intersect(findall(x->in(inputs["RESOURCES"][y],RETRO_SOURCES[x]),1:G), findall(x->x in NEW_CAP, 1:G)) ))

	## # Fix New Build error - see current GenData
	##@constraint(EP, cRetroMaxCap[y in RET_CAP], sum(EP[:vCAP][yr]/RETRO_EFFICIENCY[yr] for yr in intersect(findall(x->inputs["RESOURCES"][y]==RETRO_SOURCE[x], 1:G), findall(x->x in NEW_CAP, 1:G))) <= EP[:vRETCAP][y])

	return EP
end
