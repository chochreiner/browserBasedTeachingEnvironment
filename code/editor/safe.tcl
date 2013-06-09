package req nx::test

nx::Class create SafeInterp {
  
  :property requiredPackages:0..*
  :variable interp

  :method init {} {
    set :interp [interp create -safe]
    # TODO: hide unneeded commands in safe interp, see [interp] doc
  }

  :method getIfneededScript {pkgName pkgVersion:optional} {
    set versions [package versions $pkgName]
    if {$versions eq ""} {
      {*}[package unknown] $pkgName
      set versions [package versions $pkgName]
      if {$versions eq ""} {
	return -code error "Could not find package $pkgName"
      }
    }

    if {[info exists pkgVersion]} {
      if {$pkgVersion ni $versions} {
	return -code error \
	    "Could not find package $pkgName in version $pkgVersion"
      }
    } else {
      set pkgVersion [lindex $versions 0]
    }
    
    return [list [package ifneeded $pkgName $pkgVersion] $pkgVersion]
  }

  :public method requirePackage {pkgName pkgVersion:optional} {
    lassign [:getIfneededScript {*}[current args]] script foundVersion
    # TODO: make sure that package are only required once
    interp expose ${:interp} load
    interp expose ${:interp} source
    :eval $script
    interp hide ${:interp} load
    interp hide ${:interp} source
    return [list $pkgName $foundVersion]
  }
  :public method eval {script} {
    ${:interp} eval $script
  }
}

set si [SafeInterp new]
? {$si eval {info commands ::nsf::is}} ""
? {$si requirePackage nsf} [list nsf 2.0b5]
? {$si eval {::nsf::is object nx::Object}} 0
? {$si requirePackage nx} [list nx 2.0b5]
? {$si eval {::nsf::is object nx::Object}} 1
? {$si requirePackage nx 2.0b4} "Could not find package nx in version 2.0b4"
