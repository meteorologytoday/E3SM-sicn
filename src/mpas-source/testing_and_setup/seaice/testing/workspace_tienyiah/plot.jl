using NCDatasets

nm(x) = nomissing(x, NaN)

case_dir = "test01"
grid_dir = "$(case_dir)"
data_dir = "$(case_dir)/analysis_members"

Dataset("$(grid_dir)/grid.nc", "r") do ds
    global nCell = ds.dim["nCells"]
    global latCell = ds["latCell"][:]  |> nm .|> rad2deg
    global lonCell = ds["lonCell"][:]  |> nm .|> rad2deg
end

Dataset("$(data_dir)/timeSeriesStatsMonthly.2000-01.nc", "r") do ds
    global iceVol = ds["timeMonthly_avg_iceVolumeCell"][:] |> nm 
end


println("Data loaded")
using PyPlot
plt = PyPlot

fig, ax = plt.subplots(1, 1, constrained_layout=true)

ax.set_xlabel("Longitude")
ax.set_ylabel("Latitude")

mapping = ax.scatter(lonCell, latCell, c=iceVol, s=10, cmap=plt.get_cmap("jet"))
cb = plt.colorbar(mapping, ax=ax)
cb.ax.set_ylabel("iceVolume \$ [ \\mathrm{m}^3 / \\mathrm{m}^2] \$")



plt.show()







