# Allow generic URIs to use the registry format
silence_warnings do
  URI::Generic::USE_REGISTRY = true
end
