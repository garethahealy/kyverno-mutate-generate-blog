if [[ ! -d "test/test_helper/bats-support" ]]; then
  # Download bats-support dynamically so it doesnt need to be added into source
  git clone https://github.com/ztombol/bats-support test/test_helper/bats-support --depth 1
fi

if [[ ! -d "test/test_helper/redhatcop-bats-library" ]]; then
  # Download redhat-cop/bats-library dynamically so it doesnt need to be added into source
  git clone https://github.com/redhat-cop/bats-library test/test_helper/redhatcop-bats-library --depth 1
fi

# GNU sed is required to comment out the unused commands
if [[ $(sed --help | grep -c "GNU") -eq 0 ]]; then
  echo >&2 'ERROR: expected sed to be GNU based (https://formulae.brew.sh/formula/gnu-sed) - Aborting'
  exit 1
fi

# Remove unused commands for this example
sed -i "4s/command/#command/" test/test_helper/redhatcop-bats-library/load.bash
sed -i "5s/command/#command/" test/test_helper/redhatcop-bats-library/load.bash
sed -i "6s/command/#command/" test/test_helper/redhatcop-bats-library/load.bash