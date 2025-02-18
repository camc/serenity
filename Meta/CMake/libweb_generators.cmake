function (generate_css_implementation)
    set(LIBWEB_INPUT_FOLDER "${CMAKE_CURRENT_SOURCE_DIR}")
    invoke_generator(
            "EasingFunctions.cpp"
            Lagom::GenerateCSSEasingFunctions
            "${LIBWEB_INPUT_FOLDER}/CSS/EasingFunctions.json"
            "CSS/EasingFunctions.h"
            "CSS/EasingFunctions.cpp"
            arguments -j "${LIBWEB_INPUT_FOLDER}/CSS/EasingFunctions.json"
    )

    invoke_generator(
        "Enums.cpp"
        Lagom::GenerateCSSEnums
        "${LIBWEB_INPUT_FOLDER}/CSS/Enums.json"
        "CSS/Enums.h"
        "CSS/Enums.cpp"
        arguments -j "${LIBWEB_INPUT_FOLDER}/CSS/Enums.json"
    )

    invoke_generator(
        "MathFunctions.cpp"
        Lagom::GenerateCSSMathFunctions
        "${LIBWEB_INPUT_FOLDER}/CSS/MathFunctions.json"
        "CSS/MathFunctions.h"
        "CSS/MathFunctions.cpp"
        arguments -j "${LIBWEB_INPUT_FOLDER}/CSS/MathFunctions.json"
    )

    invoke_generator(
        "MediaFeatureID.cpp"
        Lagom::GenerateCSSMediaFeatureID
        "${LIBWEB_INPUT_FOLDER}/CSS/MediaFeatures.json"
        "CSS/MediaFeatureID.h"
        "CSS/MediaFeatureID.cpp"
        arguments -j "${LIBWEB_INPUT_FOLDER}/CSS/MediaFeatures.json"
    )

    invoke_generator(
        "PropertyID.cpp"
        Lagom::GenerateCSSPropertyID
        "${LIBWEB_INPUT_FOLDER}/CSS/Properties.json"
        "CSS/PropertyID.h"
        "CSS/PropertyID.cpp"
        arguments -j "${LIBWEB_INPUT_FOLDER}/CSS/Properties.json"
    )

    invoke_generator(
        "TransformFunctions.cpp"
        Lagom::GenerateCSSTransformFunctions
        "${LIBWEB_INPUT_FOLDER}/CSS/TransformFunctions.json"
        "CSS/TransformFunctions.h"
        "CSS/TransformFunctions.cpp"
        arguments -j "${LIBWEB_INPUT_FOLDER}/CSS/TransformFunctions.json"
    )

    invoke_generator(
        "ValueID.cpp"
        Lagom::GenerateCSSValueID
        "${LIBWEB_INPUT_FOLDER}/CSS/Identifiers.json"
        "CSS/ValueID.h"
        "CSS/ValueID.cpp"
        arguments -j "${LIBWEB_INPUT_FOLDER}/CSS/Identifiers.json"
    )

    add_custom_command(
        OUTPUT CSS/DefaultStyleSheetSource.cpp
        COMMAND "${CMAKE_COMMAND}" -E make_directory CSS
        COMMAND "${LIBWEB_INPUT_FOLDER}/Scripts/GenerateStyleSheetSource.sh" default_stylesheet_source "${LIBWEB_INPUT_FOLDER}/CSS/Default.css" > CSS/DefaultStyleSheetSource.cpp.tmp
        COMMAND "${CMAKE_COMMAND}" -E copy_if_different CSS/DefaultStyleSheetSource.cpp.tmp CSS/DefaultStyleSheetSource.cpp
        COMMAND "${CMAKE_COMMAND}" -E remove CSS/DefaultStyleSheetSource.cpp.tmp
        VERBATIM
        DEPENDS "${LIBWEB_INPUT_FOLDER}/Scripts/GenerateStyleSheetSource.sh"
        MAIN_DEPENDENCY "${LIBWEB_INPUT_FOLDER}/CSS/Default.css"
    )
    add_custom_target(generate_DefaultStyleSheetSource.cpp DEPENDS CSS/DefaultStyleSheetSource.cpp)
    add_dependencies(all_generated generate_DefaultStyleSheetSource.cpp)

    add_custom_command(
        OUTPUT CSS/QuirksModeStyleSheetSource.cpp
        COMMAND "${CMAKE_COMMAND}" -E make_directory CSS
        COMMAND "${LIBWEB_INPUT_FOLDER}/Scripts/GenerateStyleSheetSource.sh" quirks_mode_stylesheet_source "${LIBWEB_INPUT_FOLDER}/CSS/QuirksMode.css" > CSS/QuirksModeStyleSheetSource.cpp.tmp
        COMMAND "${CMAKE_COMMAND}" -E copy_if_different CSS/QuirksModeStyleSheetSource.cpp.tmp CSS/QuirksModeStyleSheetSource.cpp
        COMMAND "${CMAKE_COMMAND}" -E remove CSS/QuirksModeStyleSheetSource.cpp.tmp
        VERBATIM
        DEPENDS "${LIBWEB_INPUT_FOLDER}/Scripts/GenerateStyleSheetSource.sh"
        MAIN_DEPENDENCY "${LIBWEB_INPUT_FOLDER}/CSS/Default.css"
    )
    add_custom_target(generate_QuirksModeStyleSheetSource.cpp DEPENDS CSS/QuirksModeStyleSheetSource.cpp)
    add_dependencies(all_generated generate_QuirksModeStyleSheetSource.cpp)

endfunction()

function (generate_js_bindings target)
    set(LIBWEB_INPUT_FOLDER "${CMAKE_CURRENT_SOURCE_DIR}")
    function(libweb_js_bindings class)
        cmake_parse_arguments(PARSE_ARGV 1 LIBWEB_BINDINGS "NAMESPACE;ITERABLE;GLOBAL" "" "")
        get_filename_component(basename "${class}" NAME)

        if (LIBWEB_BINDINGS_NAMESPACE)
            set(BINDINGS_SOURCES
                "Bindings/${basename}Namespace.h"
                "Bindings/${basename}Namespace.cpp"
            )
        else()
            set(BINDINGS_SOURCES
                "Bindings/${basename}Constructor.h"
                "Bindings/${basename}Constructor.cpp"
                "Bindings/${basename}Prototype.h"
                "Bindings/${basename}Prototype.cpp"
            )
        endif()

        if(LIBWEB_BINDINGS_ITERABLE)
            list(APPEND BINDINGS_SOURCES
                "Bindings/${basename}IteratorPrototype.h"
                "Bindings/${basename}IteratorPrototype.cpp"
            )
        endif()

        if(LIBWEB_BINDINGS_GLOBAL)
            list(APPEND BINDINGS_SOURCES
                "Bindings/${basename}GlobalMixin.h"
                "Bindings/${basename}GlobalMixin.cpp"
            )
        endif()

        list(TRANSFORM BINDINGS_SOURCES PREPEND "${CMAKE_CURRENT_BINARY_DIR}/")
        target_sources(${target} PRIVATE ${BINDINGS_SOURCES})

        get_property(include_paths DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY INCLUDE_DIRECTORIES)
        list(TRANSFORM include_paths PREPEND -i)

        # Ninja expects the target name in depfiles to be relative to CMAKE_BINARY_DIR, but ${bindings_src} is
        # relative to CMAKE_CURRENT_BINARY_DIR. CMake >= 3.20 can do the rewriting transparently (CMP0116).
        set(depfile_prefix_arg "")
        if(CMAKE_GENERATOR MATCHES "^Ninja" AND NOT POLICY CMP0116)
            file(RELATIVE_PATH depfile_target ${CMAKE_BINARY_DIR} ${CMAKE_CURRENT_BINARY_DIR})
            set(depfile_prefix_arg "--depfile-prefix ${depfile_target}" )
        endif()

        add_custom_command(
            OUTPUT ${BINDINGS_SOURCES}
            COMMAND "$<TARGET_FILE:Lagom::BindingsGenerator>" -o "Bindings" --depfile "Bindings/${basename}.d"
                    ${depfile_prefix_arg} "${LIBWEB_INPUT_FOLDER}/${class}.idl" "${LIBWEB_INPUT_FOLDER}"
            VERBATIM
            COMMENT "Generating Bindings for ${class}"
            DEPENDS Lagom::BindingsGenerator
            MAIN_DEPENDENCY ${class}.idl
            DEPFILE ${CMAKE_CURRENT_BINARY_DIR}/Bindings/${basename}.d
        )

        add_custom_target(generate_${basename} DEPENDS ${BINDINGS_SOURCES})
        add_dependencies(all_generated generate_${basename})
        add_dependencies(${target} generate_${basename})

        list(APPEND LIBWEB_ALL_IDL_FILES "${LIBWEB_INPUT_FOLDER}/${class}.idl")
        set(LIBWEB_ALL_IDL_FILES ${LIBWEB_ALL_IDL_FILES} PARENT_SCOPE)
    endfunction()

    function(generate_exposed_interface_files)
        set(exposed_interface_sources
            Forward.h IntrinsicDefinitions.cpp
            DedicatedWorkerExposedInterfaces.cpp DedicatedWorkerExposedInterfaces.h
            SharedWorkerExposedInterfaces.cpp SharedWorkerExposedInterfaces.h
            WindowExposedInterfaces.cpp WindowExposedInterfaces.h)
        list(TRANSFORM exposed_interface_sources PREPEND "Bindings/")
        add_custom_command(
            OUTPUT  ${exposed_interface_sources}
            COMMAND "${CMAKE_COMMAND}" -E make_directory "tmp"
            COMMAND $<TARGET_FILE:Lagom::GenerateWindowOrWorkerInterfaces> -o "${CMAKE_CURRENT_BINARY_DIR}/tmp" -b "${LIBWEB_INPUT_FOLDER}" ${LIBWEB_ALL_IDL_FILES}
            COMMAND "${CMAKE_COMMAND}" -E copy_if_different tmp/Forward.h "Bindings/Forward.h"
            COMMAND "${CMAKE_COMMAND}" -E copy_if_different tmp/IntrinsicDefinitions.cpp "Bindings/IntrinsicDefinitions.cpp"
            COMMAND "${CMAKE_COMMAND}" -E copy_if_different tmp/DedicatedWorkerExposedInterfaces.h "Bindings/DedicatedWorkerExposedInterfaces.h"
            COMMAND "${CMAKE_COMMAND}" -E copy_if_different tmp/DedicatedWorkerExposedInterfaces.cpp "Bindings/DedicatedWorkerExposedInterfaces.cpp"
            COMMAND "${CMAKE_COMMAND}" -E copy_if_different tmp/SharedWorkerExposedInterfaces.h "Bindings/SharedWorkerExposedInterfaces.h"
            COMMAND "${CMAKE_COMMAND}" -E copy_if_different tmp/SharedWorkerExposedInterfaces.cpp "Bindings/SharedWorkerExposedInterfaces.cpp"
            COMMAND "${CMAKE_COMMAND}" -E copy_if_different tmp/WindowExposedInterfaces.h "Bindings/WindowExposedInterfaces.h"
            COMMAND "${CMAKE_COMMAND}" -E copy_if_different tmp/WindowExposedInterfaces.cpp "Bindings/WindowExposedInterfaces.cpp"
            COMMAND "${CMAKE_COMMAND}" -E remove_directory "${CMAKE_CURRENT_BINARY_DIR}/tmp"
            VERBATIM
            DEPENDS Lagom::GenerateWindowOrWorkerInterfaces ${LIBWEB_ALL_IDL_FILES}
        )
        target_sources(${target} PRIVATE ${exposed_interface_sources})
        add_custom_target(generate_exposed_interfaces DEPENDS ${exposed_interface_sources})
        add_dependencies(all_generated generate_exposed_interfaces)
        add_dependencies(${target} generate_exposed_interfaces)
    endfunction()

    include("idl_files.cmake")
    generate_exposed_interface_files()

endfunction()
