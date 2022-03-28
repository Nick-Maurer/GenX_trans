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
	write_power(path::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for writing the different values of power generated by the different technologies in operation.
"""
function write_power_fleccs(path::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	dfGen_ccs = inputs["dfGen_ccs"]
	FLECCS_ALL = inputs["FLECCS_ALL"]
	N_F = inputs["N_F"]
	Z = inputs["Z"]
	T = inputs["T"]
	G_F = inputs["G_F"]
	# the number of rows for FLECCS generator 
	#n = length(dfGen_ccs[!,"Resource"])/length(N_F)

    # the number of subcompoents 
	N = length(N_F)

	dfPower_FLECCS = DataFrame(Resource = dfGen_ccs[!,:Resource], Zone = dfGen_ccs[!,:Zone], AnnualSum = Array{Union{Missing,Float32}}(undef, length(dfGen_ccs[!,:Resource])))
	
	FLECCS_output = zeros(G_F*N,T)

	for y in FLECCS_ALL
	    for i in N_F
		    FLECCS_output[(y-1)*N + i,:] = value.(EP[:vFLECCS_output])[y,i,:]
		end
		for i in [last(N_F)]
			FLECCS_output[(y-1)*N + i,:] = value.(EP[:eCCS_net])[y,:]
		end
	end


	if setup["ParameterScale"] ==1
		for i in 1:G_F*N
			dfPower_FLECCS[!,:AnnualSum][i] = sum(inputs["omega"].* (FLECCS_output[i,:])) * ModelScalingFactor
		end
		dfPower_FLECCS = hcat(dfPower_FLECCS, DataFrame(FLECCS_output *ModelScalingFactor, :auto))
	else
		for i in 1:G_F*N
			dfPower_FLECCS[!,:AnnualSum][i] = sum(inputs["omega"].* (FLECCS_output[i,:])) 
		end
		dfPower_FLECCS = hcat(dfPower_FLECCS, DataFrame(FLECCS_output, :auto))
	end






	#auxNew_Names=[Symbol("Resource");Symbol("Zone");Symbol("AnnualSum");[Symbol("t$t") for t in 1:T]]
	#rename!(dfPower,auxNew_Names)

	#total = DataFrame(["Total" 0 sum(dfPower[!,:AnnualSum]) fill(0.0, (1,T))], :auto)
	#for t in 1:T
	#	if v"1.3" <= VERSION < v"1.4"
	#		total[!,t+3] .= sum(dfPower[!,Symbol("t$t")][1: size(dfPower)[1]])
	#	elseif v"1.4" <= VERSION < v"1.7"
	#		total[:,t+3] .= sum(dfPower[:,Symbol("t$t")][1: size(dfPower)[1]])
	#	end
	#end
	#rename!(total,auxNew_Names)
	#dfPower = vcat(dfPower, total)
	#dfPower_FLECCS = dftranspose(dfPower_FLECCS, false)
	#rename!(dfPower_FLECCS,:Compressor => :Other_auxiliary)
	#rename!(dfPower_FLECCS,:BOP => :Net_Power)


 	CSV.write(joinpath(path,"power_FLECCS.csv"),dftranspose(dfPower_FLECCS, false), writeheader=false)
	return dfPower_FLECCS
end
