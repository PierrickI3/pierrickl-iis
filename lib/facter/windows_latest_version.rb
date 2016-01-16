Facter.add(:windows_latest_version) do
  setcode do
		Dir.chdir("C:/daas-cache")
		files = Dir.glob("9600.16384.WINBLUE.*")

		latestversion = files.max()
		latestversion
	end
end
