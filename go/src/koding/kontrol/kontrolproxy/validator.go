package main

import (
	"fmt"
	"koding/kontrol/kontrolproxy/proxyconfig"
	"regexp"
)

type filter struct {
	mode     string
	validate func() bool
}

type Validator struct {
	filters map[string]filter
	rules   proxyconfig.Restriction
	user    *UserInfo
}

func validator(rules proxyconfig.Restriction, user *UserInfo) *Validator {
	validator := &Validator{
		rules:   rules,
		user:    user,
		filters: make(map[string]filter),
	}
	return validator
}

func (v *Validator) addFilter(name, mode string, validateFn func() bool) {
	v.filters[name] = filter{
		mode:     mode,
		validate: validateFn,
	}
}

func (v *Validator) IP() *Validator {
	if !v.rules.IP.Enabled {
		return v
	}

	f := func() bool {
		if v.rules.IP.Rule == "" {
			return true // assume allowed for all
		}

		rule, err := regexp.Compile(v.rules.IP.Rule)
		if err != nil {
			return true // dont block anyone if regex compile get wrong
		}

		return rule.MatchString(v.user.IP)
	}
	v.addFilter("ip", v.rules.IP.Mode, f)
	return v
}

func (v *Validator) Country() *Validator {
	if !v.rules.Country.Enabled {
		return v
	}

	f := func() bool {
		// assume matched for an empty array
		if len(v.rules.Country.Rule) == 0 {
			return true // assume all
		}

		emptystrings := 0
		for _, country := range v.rules.Country.Rule {
			if country == "" {
				emptystrings++
			}
			if country == v.user.Country {
				return true
			}
		}

		// if the array has all empty slices assume matched
		if emptystrings == len(v.rules.Country.Rule) {
			return true //
		}

		return false
	}

	v.addFilter("domain", v.rules.Country.Mode, f)
	return v
}

func (v *Validator) Check() (string, bool) {
	for name, filter := range v.filters {
		if filter.mode == "blacklist" && filter.validate() {
			return fmt.Sprintf("user is blocked via %s\n", name), false
		} else if filter.mode == "whitelist" && !filter.validate() {
			return fmt.Sprintf("user is blocked via %s\n", name), false
		}
	}

	// user is validated because none of the rules applied to him
	fmt.Println("user is validated")
	return fmt.Sprintf("user is validated\n"), true
}
