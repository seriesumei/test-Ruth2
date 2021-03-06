//*********************************************************************************
//**   This program is free software: you can redistribute it and/or modify
//**   it under the terms of the GNU Affero General Public License as
//**   published by the Free Software Foundation, either version 3 of the
//**   License, or (at your option) any later version.
//**
//**   This program is distributed in the hope that it will be useful,
//**   but WITHOUT ANY WARRANTY; without even the implied warranty of
//**   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//**   GNU Affero General Public License for more details.
//**
//**   You should have received a copy of the GNU Affero General Public License
//**   along with this program.  If not, see <https://www.gnu.org/licenses/>
//*********************************************************************************

// ss-c 31Dec2018 <seriesumei@avimail.org> - Combined HUD
// ss-d 03Jan2019 <seriesumei@avimail.org> - Add skin panel
// ss-e 10Feb2019 <seriesumei@avimail.org> - Add option panel
// ss-f 31Mar2019 <seriesumei@avimail.org> - Fix textures for SL vs OpenSim
// ss-g 02Apr2019 <seriesumei@avimail.org> - Add skin buttons and tweak textures

// This builds a multi-paned HUD for Ruth/Roth that includes the existing
// alpha HUD mesh and adds panes for a different skin applier than Shin's
// and an Options pane that currently has fingernail shape/color and toenail
// color buttons.
//
// To build the 'uniHUD' from scratch you will need to:
// * Upload or obtain via whatever means the Alpha HUD mesh and the 'doll'
//   mesh.  This script will throw an error if you start with a pre-linked
//   alpha HUD but it should work anyway.  To prepare the alpha hud and doll
//   meshes:
//   * Remove all scripts
//   * Make sure that the 'rotatebar' link is the root of the HUD linkset and
//     the 'chest' link is the root of the doll linkset.  Thse are used for
//     positioning, even so SL gets the positioning wrong compares to OpenSim.
// * Create a new empty box prim named 'Object' and take a copy of it into
//   inventory
// * Copy the folloing objects into the new box's inventory on the ground:
//   * the new box from inventory created above and name it 'Object'
//   * the alpha HUD mesh and name it 'alpha-hud'
//   * if the doll mes is not already linked into the alpha HUD linkset copy
//     it and name it 'doll'
//   * the button meshes named '2x1 button' and 5x button'
//   * this script
// * Light fuse (touch the box prim) and get away, the new HUD will be
//   assembled around the box prim which will become the root prim of the HUD.
// * The alpha HUD and the doll will not be linked as they may need size
//   and/or position adjustments depending on how your mesh is linked.  Since
//   they are both linksets you do not want to link them to the main HUD until
//   you are very satisfied with their position.  Then link them and rejoice.
// * Rename the former root prim of the alpha HUD mesh, if it was the rotation
//   bar at the bottom name it 'rotatebar'.  Remove any script if it is still
//   present.
// * Rename the former root prim of the doll according to the usual doll link
//   names.
// * Make any position and size adjustments as necessary to the alpha HUD mesh
//   and doll, then link them both to the new HUD root prim.  Make sure that
//   the center square HUD prim is last so it remains the root of the linkset.
// * Remove this script from the HUD root prim and copy in the HUD script(s).
// * The other objects are also not needed any longer in the root prim and
//   can be removed.

vector build_pos;
integer link_me = FALSE;
integer FINI = FALSE;
integer counter = 0;

key bar_texture;
key hud_texture;
key options_texture;
key fingernails_shape_texture;

vector bar_size = <0.5, 0.5, 0.04>;
vector hud_size = <0.5, 0.5, 0.5>;
vector color_button_size = <0.01, 0.145, 0.025>;
vector shape_button_size = <0.01, 0.295, 0.051>;

// Spew debug info
integer VERBOSE = TRUE;

// Hack to detect Second Life vs OpenSim
// Relies on a bug in llParseString2List() in SL
// http://grimore.org/fuss/lsl/bugs#splitting_strings_to_lists
integer is_SL() {
    string sa = "12999";
//    list OS = [1,2,9,9,9];
    list SL = [1,2,999];
    list la = llParseString2List(sa, [], ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]);
    return (la == SL);
}

// The four textures used in the HUD referenced below are included in the repo:
// bar_texture: ruth 2.0 hud header.png
// hud_texture: ruth 2.0 hud background gradient.png
// options_texture: ruth 2.0 hud options gradient.png
// fingernails_shape_texture: ruth 2.0 hud fingernails shape.png

get_textures() {
    if (is_SL()) {
        // Textures in SL
        // The textures listed are full-perm uploaded by seriesumei Resident
        bar_texture = "d5aeccd4-f3ff-bea6-1296-07e8e0453275";
        hud_texture = "76dbff9c-c2fd-ffe9-a37f-cb9e42f722fe";
        options_texture = "1186285b-cc82-7602-71f0-8ad0eb1762b2";
        fingernails_shape_texture = "fb6ee827-3c3e-99a8-0e33-47015c0845a9";
    } else {
        string grid_name = "";

        // This will not compile in Second Life as it is an OpenSim-specific
        // function.  Comment out the following line for SL:
        grid_name = osGetGridName();

        if (grid_name == "OSGrid") {
            // Textures in OSGrid
            // TODO: Bad assumption that OpenSim == OSGrid, how do we detect
            //       which grid?  osGetGridName() is an option but does not
            //       compile in SL so editing the script would stll be required.
            //       Maybe we don't care too much about that?
            // The textures listed are full-perm uploaded by serie sumei to OSGrid
            bar_texture = "dc2612bd-e230-47f3-8888-d9a14b652f7d";
            hud_texture = "c76f327a-a431-4219-8913-78c7adfe0d02";
            options_texture = "86717f80-d201-4cf5-ab4c-1d77e5bd8e55";
            fingernails_shape_texture = "fe777245-4fa2-4834-b794-0c29fa3e1fcf";
        } else {
            log("OpenSim detected but grid " + grid_name() + " unknown, using blank textures");
            bar_texture = TEXTURE_BLANK;
            hud_texture = TEXTURE_BLANK;
            options_texture = TEXTURE_BLANK;
            fingernails_shape_texture = TEXTURE_BLANK;
        }
    }
}

log(string txt) {
    if (VERBOSE) {
        llOwnerSay(txt);
    }
}

rez_object(string name, vector delta, vector rot) {
    vector build_pos = llGetPos();
    build_pos += delta;;

    log("Rezzing " + name);
    llRezObject(
        name,
        build_pos,
        <0.0, 0.0, 0.0>,
        llEuler2Rot(rot),
        0
    );
}

configre_bar(string name, float offset_y) {
    log("Configuring " + name);
    llSetLinkPrimitiveParamsFast(2, [
        PRIM_NAME, name,
        PRIM_TEXTURE, ALL_SIDES, bar_texture, <1.0, 0.1, 0.0>, <0.0, offset_y, 0.0>, 0.0,
        PRIM_TEXTURE, 0, TEXTURE_TRANSPARENT, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0,
        PRIM_TEXTURE, 5, TEXTURE_TRANSPARENT, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0,
        PRIM_COLOR, ALL_SIDES, <1.0, 1.0, 1.0>, 1.00,
        PRIM_SIZE, bar_size
    ]);
}

configure_color_buttons(string name) {
    log("Configuring " + name);
    llSetLinkPrimitiveParamsFast(2, [
        PRIM_NAME, name,
        PRIM_COLOR, ALL_SIDES, <1.0, 1.0, 1.0>, 1.00,
        PRIM_COLOR, 3, <0.3, 0.3, 0.3>, 1.00,
        PRIM_COLOR, 4, <0.6, 0.6, 0.6>, 1.00,
        PRIM_SIZE, color_button_size
    ]);
}

default {
    touch_start(integer total_number) {
        get_textures();
        counter = 0;
        // set up root prim
        log("Configuring root");
        llSetLinkPrimitiveParamsFast(LINK_THIS, [
            PRIM_NAME, "HUD base",
            PRIM_SIZE, <0.1, 0.1, 0.1>,
            PRIM_TEXTURE, ALL_SIDES, TEXTURE_TRANSPARENT, <0,0,0>, <0.0, 0.455, 0.0>, 0.0,
            PRIM_COLOR, ALL_SIDES, <1.0, 1.0, 1.0>, 1.00
        ]);

        // See if we'll be able to link to trigger build
        llRequestPermissions(llGetOwner(), PERMISSION_CHANGE_LINKS);
    }

    run_time_permissions(integer perm) {
        // Only bother rezzing the object if will be able to link it.
        if (perm & PERMISSION_CHANGE_LINKS) {
            // log("Rezzing south");
            link_me = TRUE;
            rez_object("Object", <0.0, 0.0, -0.5>, <0.0, 0.0, 0.0>);
        } else {
            llOwnerSay("unable to link objects, aborting build");
        }
    }

    object_rez(key id) {
        counter++;
        integer i = llGetNumberOfPrims();
        log("counter="+(string)counter);

        if (link_me) {
            llCreateLink(id, TRUE);
            link_me = FALSE;
        }

        if (counter == 1) {
            configre_bar("minbar", 0.440);

            // log("Rezzing east");
            link_me = TRUE;
            rez_object("Object", <0.0, -0.5, 0.0>, <-PI_BY_TWO, 0.0, 0.0>);
        }
        else if (counter == 2) {
            configre_bar("optionbar", 0.065);

            // log("Rezzing north");
            link_me = TRUE;
            rez_object("Object", <0.0, 0.0, 0.5>, <PI, 0.0, 0.0>);
        }
        else if (counter == 3) {
            configre_bar("skinbar", 0.190);

            // log("Rezzing west");
            link_me = TRUE;
            rez_object("Object", <0.0, 0.5, 0.0>, <PI_BY_TWO, 0.0, 0.0>);
        }
        else if (counter == 4) {
            configre_bar("alphabar", 0.314);

            log("Rezzing option HUD");
            link_me = TRUE;
            rez_object("Object", <0.0, -0.76953, 0.0>, <-PI_BY_TWO, 0.0, 0.0>);
        }
        else if (counter == 5) {
            log("Configuring option HUD");
            llSetLinkPrimitiveParamsFast(2, [
                PRIM_NAME, "optionbox",
                PRIM_TEXTURE, ALL_SIDES, options_texture, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0,
                PRIM_COLOR, ALL_SIDES, <1.0, 1.0, 1.0>, 1.00,
                PRIM_SIZE, hud_size
            ]);

            log("Rezzing skin HUD");
            link_me = TRUE;
            rez_object("Object", <0.0, 0.0, 0.76953>, <PI, 0.0, 0.0>);
        }
        else if (counter == 6) {
            log("Configuring skin HUD");
            llSetLinkPrimitiveParamsFast(2, [
                PRIM_NAME, "skinbox",
                PRIM_TEXTURE, ALL_SIDES, hud_texture, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0,
                PRIM_COLOR, ALL_SIDES, <1.0, 1.0, 1.0>, 1.00,
                PRIM_SIZE, hud_size
            ]);

            log("Rezzing alpha HUD");
            link_me = FALSE;
            rez_object("alpha-hud", <0.0, 0.811, 0.0>, <PI_BY_TWO, 0.0, -PI_BY_TWO>);
        }
        else if (counter == 7) {
            log("Rezzing alpha doll");
            link_me = FALSE;
            rez_object("doll", <0.0, 0.78, 0.0>, <PI_BY_TWO, 0.0, -PI_BY_TWO>);
        }
        else if (counter == 8) {
            log("Rezzing buttons");
            link_me = TRUE;
            rez_object("5x button", <-0.2488, -0.6, -0.03027>, <-PI_BY_TWO, 0.0, 0.0>);
        }
        else if (counter == 9) {
            configure_color_buttons("fnc0");

            log("Rezzing buttons");
            link_me = TRUE;
            rez_object("5x button", <-0.2488, -0.6, 0.11965>, <-PI_BY_TWO, 0.0, 0.0>);
        }
        else if (counter == 10) {
            configure_color_buttons("fnc1");

            log("Rezzing buttons");
            link_me = TRUE;
            rez_object("5x button", <-0.2488, -0.64849, 0.04468>, <-PI_BY_TWO, 0.0, 0.0>);
        }
        else if (counter == 11) {
            log("Configuring buttons");
            llSetLinkPrimitiveParamsFast(2, [
                PRIM_NAME, "fns0",
                PRIM_TEXTURE, ALL_SIDES, TEXTURE_BLANK, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0,
                PRIM_TEXTURE, 5, fingernails_shape_texture, <0.25, 1.0, 0.0>, <-0.375, 0.0, 0.0>, 0.0,
                PRIM_TEXTURE, 6, fingernails_shape_texture, <0.25, 1.0, 0.0>, <-0.125, 0.0, 0.0>, 0.0,
                PRIM_TEXTURE, 1, fingernails_shape_texture, <0.25, 1.0, 0.0>, <0.125, 0.0, 0.0>, 0.0,
                PRIM_TEXTURE, 2, fingernails_shape_texture, <0.25, 1.0, 0.0>, <0.375, 0.0, 0.0>, 0.0,
                PRIM_COLOR, ALL_SIDES, <1.0, 1.0, 1.0>, 1.00,
                PRIM_COLOR, 3, <0.3, 0.3, 0.3>, 1.00,
                PRIM_COLOR, 4, <0.6, 0.6, 0.6>, 1.00,
                PRIM_COLOR, 0, <0.0, 0.0, 0.0>, 1.00,
                PRIM_SIZE, shape_button_size
            ]);

            log("Rezzing buttons");
            link_me = TRUE;
            rez_object("5x button", <-0.2488, -0.73976, -0.03027>, <-PI_BY_TWO, 0.0, 0.0>);
        }
        else if (counter == 12) {
            configure_color_buttons("tnc0");

            log("Rezzing buttons");
            link_me = TRUE;
            rez_object("5x button", <-0.2488, -0.73976, 0.11965>, <-PI_BY_TWO, 0.0, 0.0>);
        }
        else if (counter == 13) {
            configure_color_buttons("tnc1");

            log("Rezzing buttons");
            link_me = TRUE;
            // z=0.76953
            rez_object("1x2 button", <-0.25, -0.1, 0.6333>, <PI, 0.0, 0.0>);
        }
        else if (counter == 14) {
            log("Configuring skin button");
            llSetLinkPrimitiveParamsFast(2, [
                PRIM_NAME, "skin1",
                PRIM_TEXTURE, ALL_SIDES, TEXTURE_TRANSPARENT, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0,
                PRIM_TEXTURE, 4, TEXTURE_BLANK, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0
            ]);

            log("Rezzing buttons");
            link_me = TRUE;
            // z=0.76953
            rez_object("1x2 button", <-0.25, 0.1, 0.6333>, <PI, 0.0, 0.0>);
        }
        else if (counter == 15) {
            log("Configuring skin button");
            llSetLinkPrimitiveParamsFast(2, [
                PRIM_NAME, "skin2",
                PRIM_TEXTURE, ALL_SIDES, TEXTURE_TRANSPARENT, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0,
                PRIM_TEXTURE, 4, TEXTURE_BLANK, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0
            ]);

            log("Rezzing buttons");
            link_me = TRUE;
            // z=0.76953
            rez_object("1x2 button", <-0.25, -0.1, 0.7333>, <PI, 0.0, 0.0>);
        }
        else if (counter == 16) {
            log("Configuring skin button");
            llSetLinkPrimitiveParamsFast(2, [
                PRIM_NAME, "skin3",
                PRIM_TEXTURE, ALL_SIDES, TEXTURE_TRANSPARENT, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0,
                PRIM_TEXTURE, 4, TEXTURE_BLANK, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0
            ]);

            log("Rezzing buttons");
            link_me = TRUE;
            // z=0.76953
            rez_object("1x2 button", <-0.25, 0.1, 0.7333>, <PI, 0.0, 0.0>);
        }
        else if (counter == 17) {
            log("Configuring skin button");
            llSetLinkPrimitiveParamsFast(2, [
                PRIM_NAME, "skin4",
                PRIM_TEXTURE, ALL_SIDES, TEXTURE_TRANSPARENT, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0,
                PRIM_TEXTURE, 4, TEXTURE_BLANK, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0
            ]);

            log("Rezzing buttons");
            link_me = TRUE;
            // z=0.76953
            rez_object("1x2 button", <-0.25, -0.1, 0.8333>, <PI, 0.0, 0.0>);
        }
        else if (counter == 18) {
            log("Configuring skin button");
            llSetLinkPrimitiveParamsFast(2, [
                PRIM_NAME, "skin5",
                PRIM_TEXTURE, ALL_SIDES, TEXTURE_TRANSPARENT, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0,
                PRIM_TEXTURE, 4, TEXTURE_BLANK, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0
            ]);

            log("Rezzing buttons");
            link_me = TRUE;
            // z=0.76953
            rez_object("1x2 button", <-0.25, 0.1, 0.8333>, <PI, 0.0, 0.0>);
        }
        else if (counter == 19) {
            log("Configuring skin button");
            llSetLinkPrimitiveParamsFast(2, [
                PRIM_NAME, "skin6",
                PRIM_TEXTURE, ALL_SIDES, TEXTURE_TRANSPARENT, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0,
                PRIM_TEXTURE, 4, TEXTURE_BLANK, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0
            ]);

            log("Rezzing buttons");
            link_me = TRUE;
            // z=0.76953
            rez_object("1x2 button", <-0.25, -0.1, 0.9333>, <PI, 0.0, 0.0>);
        }
        else if (counter == 20) {
            log("Configuring skin button");
            llSetLinkPrimitiveParamsFast(2, [
                PRIM_NAME, "skin7",
                PRIM_TEXTURE, ALL_SIDES, TEXTURE_TRANSPARENT, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0,
                PRIM_TEXTURE, 4, TEXTURE_BLANK, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0
            ]);

            log("Rezzing buttons");
            link_me = TRUE;
            // z=0.76953
            rez_object("1x2 button", <-0.25, 0.1, 0.9333>, <PI, 0.0, 0.0>);
        }
        else if (counter == 21) {
            log("Configuring skin button");
            llSetLinkPrimitiveParamsFast(2, [
                PRIM_NAME, "skin8",
                PRIM_TEXTURE, ALL_SIDES, TEXTURE_TRANSPARENT, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0,
                PRIM_TEXTURE, 4, TEXTURE_BLANK, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0
            ]);

        }
    }
}
