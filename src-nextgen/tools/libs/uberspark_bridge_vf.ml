(*===========================================================================*)
(*===========================================================================*)
(* uberSpark bridge module interface implementation -- vf bridge submodule *)
(*	 author: amit vasudevan (amitvasudevan@acm.org) *)
(*===========================================================================*)
(*===========================================================================*)


open Unix
open Yojson

(*---------------------------------------------------------------------------*)
(*---------------------------------------------------------------------------*)
(* variables *)
(*---------------------------------------------------------------------------*)
(*---------------------------------------------------------------------------*)

(* uberspark-manifest json node variable *)	
let json_node_uberspark_manifest_var: Uberspark_manifest.json_node_uberspark_manifest_t = {
	f_manifest_node_types = [ "uberspark-bridge-vf" ];
	f_uberspark_min_version = "any";
	f_uberspark_max_version = "any";
};;

(* uberspark-bridge-cc json node variable *)	
let json_node_uberspark_bridge_vf_var: Uberspark_manifest.Bridge.Vf.json_node_uberspark_bridge_vf_t = {
	json_node_bridge_hdr_var = { btype = "";
				bname = "";
				execname = "";
				path = "";
				devenv = "";
				arch = "";
				cpu = "";
				version = "";
				params = [];
				container_fname = "";
				namespace = "";
	};
	bridge_cmd = [];
};;



(*---------------------------------------------------------------------------*)
(*---------------------------------------------------------------------------*)
(* interface definitions *)
(*---------------------------------------------------------------------------*)
(*---------------------------------------------------------------------------*)


let load_from_json
	(mf_json : Yojson.Basic.json)
	: bool =

	let retval = ref false in

	let rval_json_node_uberspark_bridge_vf_var = Uberspark_manifest.Bridge.Vf.json_node_uberspark_bridge_vf_to_var  
		mf_json json_node_uberspark_bridge_vf_var in

	if rval_json_node_uberspark_bridge_vf_var then begin
		retval := true;
	end else begin
		retval := false;
	end;

	(!retval)
;;


let load_from_file 
	(json_file : string)
	: bool =
	let retval = ref false in
	Uberspark_logger.log ~lvl:Uberspark_logger.Debug "loading vf-bridge settings from file: %s" json_file;

	let (rval, mf_json) = Uberspark_manifest.get_json_for_manifest json_file in

		if rval then begin

			let rval = Uberspark_manifest.json_node_uberspark_manifest_to_var mf_json json_node_uberspark_manifest_var in

			if rval then begin
					retval := load_from_json mf_json; 
			end	else begin
					retval := false;
			end;

		end	else begin
				retval := false;
		end;

	(!retval)
;;



let load 
	(bridge_ns : string)
	: bool =
	let bridge_ns_json_path = (Uberspark_namespace.get_namespace_root_dir_prefix ()) ^ "/" ^ Uberspark_namespace.namespace_root ^ "/" ^
		Uberspark_namespace.namespace_bridge_vf_bridge ^ "/" ^ bridge_ns ^ "/" ^
		Uberspark_namespace.namespace_root_mf_filename in
		(load_from_file bridge_ns_json_path)
;;


let store_to_file 
	(json_file : string)
	: bool =
	Uberspark_logger.log ~lvl:Uberspark_logger.Debug "storing vf-bridge settings to file: %s" json_file;

	Uberspark_manifest.write_to_file json_file 
		[
			(Uberspark_manifest.json_node_uberspark_manifest_var_to_jsonstr json_node_uberspark_manifest_var);
			(Uberspark_manifest.Bridge.Vf.json_node_uberspark_bridge_vf_var_to_jsonstr json_node_uberspark_bridge_vf_var);
		];

	(true)
;;


let store 
	()
	: bool =
	let retval = ref false in 
    let bridge_ns = json_node_uberspark_bridge_vf_var.json_node_bridge_hdr_var.btype ^ "/" ^
		json_node_uberspark_bridge_vf_var.json_node_bridge_hdr_var.devenv ^ "/" ^
		json_node_uberspark_bridge_vf_var.json_node_bridge_hdr_var.arch ^ "/" ^
		json_node_uberspark_bridge_vf_var.json_node_bridge_hdr_var.cpu ^ "/" ^
		json_node_uberspark_bridge_vf_var.json_node_bridge_hdr_var.bname ^ "/" ^
		json_node_uberspark_bridge_vf_var.json_node_bridge_hdr_var.version in
	let bridge_ns_json_path = (Uberspark_namespace.get_namespace_root_dir_prefix ()) ^ "/" ^ Uberspark_namespace.namespace_root ^ "/" ^
		Uberspark_namespace.namespace_bridge_vf_bridge ^ "/" ^ bridge_ns in
	let bridge_ns_json_filename = bridge_ns_json_path ^ "/" ^
		Uberspark_namespace.namespace_root_mf_filename in

	(* make the namespace directory *)
	Uberspark_osservices.mkdir ~parent:true bridge_ns_json_path (`Octal 0o0777);

	retval := store_to_file bridge_ns_json_filename;

	(* check if bridge type is container, if so store dockerfile *)
	if !retval && json_node_uberspark_bridge_vf_var.json_node_bridge_hdr_var.btype = "container" then
		begin
			let input_bridge_dockerfile = json_node_uberspark_bridge_vf_var.json_node_bridge_hdr_var.container_fname in 
			let output_bridge_dockerfile = bridge_ns_json_path ^ "/uberspark-bridge.Dockerfile" in 
				Uberspark_osservices.file_copy input_bridge_dockerfile output_bridge_dockerfile;
		end
	;

	(!retval)
;;


let build 
	()
	: bool =

	let retval = ref false in

	if json_node_uberspark_bridge_vf_var.json_node_bridge_hdr_var.btype = "container" then
		begin
			let bridge_ns = Uberspark_namespace.namespace_bridge_vf_bridge ^ "/" ^
				json_node_uberspark_bridge_vf_var.json_node_bridge_hdr_var.btype ^ "/" ^
				json_node_uberspark_bridge_vf_var.json_node_bridge_hdr_var.devenv ^ "/" ^
				json_node_uberspark_bridge_vf_var.json_node_bridge_hdr_var.arch ^ "/" ^
				json_node_uberspark_bridge_vf_var.json_node_bridge_hdr_var.cpu ^ "/" ^
				json_node_uberspark_bridge_vf_var.json_node_bridge_hdr_var.bname ^ "/" ^
				json_node_uberspark_bridge_vf_var.json_node_bridge_hdr_var.version in
			let bridge_container_path = (Uberspark_namespace.get_namespace_root_dir_prefix ()) ^ "/" ^ Uberspark_namespace.namespace_root ^ "/" ^ bridge_ns in

			Uberspark_logger.log "building vf-bridge: %s" bridge_ns;

			if (Container.build_image bridge_container_path bridge_ns) == 0 then begin	
				retval := true;
			end else begin
				Uberspark_logger.log ~lvl:Uberspark_logger.Error "could not build vf-bridge!"; 
				retval := false;
			end
			;
										
		end
	else
		begin
			Uberspark_logger.log ~lvl:Uberspark_logger.Warn "ignoring build command for 'native' bridge";
			retval := true;
		end
	;

	(!retval)
;;





(*
	input is a set of c files as string list
*)

let invoke 
	?(context_path_builddir = ".")
	(c_file_list : string list)
	(context_path : string)
	: bool =

	let retval = ref false in
	let d_cmd = ref "" in
	let c_files_str = ref "" in

	(* iterate over c file list and build a string *)
	List.iter (fun c_filename -> 
		c_files_str := !c_files_str ^ " " ^ c_filename;
	) c_file_list;

	(* construct command line using bridge_cmd variable from bridge definition *)
	for li = 0 to (List.length json_node_uberspark_bridge_vf_var.bridge_cmd) - 1 do begin
		let b_cmd = (List.nth json_node_uberspark_bridge_vf_var.bridge_cmd li) in

		(* substitute SOURCE_C_FILES within b_cmd if any *)
        let b_cmd_substituted = Str.global_replace (Str.regexp "$(SOURCE_C_FILES)") 
                !c_files_str b_cmd in

		if li == 0 then begin
			d_cmd := b_cmd_substituted;
		end else begin
			d_cmd := !d_cmd ^ " && " ^ b_cmd_substituted;
		end;

	end done;

	
	Uberspark_logger.log ~lvl:Uberspark_logger.Debug "d_cmd=%s" !d_cmd;

	(* construct bridge namespace *)
	let bridge_ns = Uberspark_namespace.namespace_bridge_vf_bridge ^ "/" ^
		json_node_uberspark_bridge_vf_var.json_node_bridge_hdr_var.btype ^ "/" ^
		json_node_uberspark_bridge_vf_var.json_node_bridge_hdr_var.devenv ^ "/" ^
		json_node_uberspark_bridge_vf_var.json_node_bridge_hdr_var.arch ^ "/" ^
		json_node_uberspark_bridge_vf_var.json_node_bridge_hdr_var.cpu ^ "/" ^
		json_node_uberspark_bridge_vf_var.json_node_bridge_hdr_var.bname ^ "/" ^
		json_node_uberspark_bridge_vf_var.json_node_bridge_hdr_var.version in

	(* invoke the verification bridge *)
	if json_node_uberspark_bridge_vf_var.json_node_bridge_hdr_var.btype = "container" then begin
		if ( (Container.run_image ~context_path_builddir:context_path_builddir "." !d_cmd bridge_ns) == 0 ) then begin
			retval := true;
		end else begin
			retval := false;
		end;
	end else begin
		if ( (Native.run_shell_command  ~context_path_builddir:context_path_builddir "." !d_cmd bridge_ns) == 0 ) then begin
			retval := true;
		end else begin
			retval := false;
		end;
	end;

	(!retval)
;;
