pragma circom 2.0.0;

include "../circuits/smt/smtverifier.circom";
include "../circuits/eddsaposeidon.circom";
include "../circuits/comparators.circom";
include "../circuits/comparators.circom";
include "./membership.circom";
include "../circuits/mux1.circom";

// verifiable Presentation circuit
template vp(n_attr,n) {
    signal input set[n]; 
    signal input key;
    signal input attributes[n_attr];
    signal input expose_index[n_attr];
    signal output exposed_attributes[n_attr];
    signal output issuer_id_out;
    signal output set_membership_out;


    signal input credential_lemma;  // Root of the credential sparse merkle tree
    signal input issuer_pk[2];
    signal input issuer_signature[3]; // Verifiable credential signature
    signal input siblings[10];
    signal input issuer_id;

    // Data integrity check
    component smt=SMTVerifier(10);
    smt.enabled<==1;
    smt.root<==credential_lemma;
    smt.siblings<==siblings;
    smt.key<==key;
    smt.oldKey<==0;
    smt.oldValue<==0;
    smt.isOld0<==0;
    smt.value<==attributes[1];
    smt.fnc<==0;

    // Issuer signature check
    component ecdsa=EdDSAPoseidonVerifier();
    ecdsa.enabled<==1;
    ecdsa.Ax<==issuer_pk[0];
    ecdsa.Ay<==issuer_pk[1];
    ecdsa.R8x<==issuer_signature[0];
    ecdsa.R8y<==issuer_signature[1];
    ecdsa.S<==issuer_signature[2];
    ecdsa.M<==credential_lemma;

   




    // Membership check
    component set_membership=SetMembership(n);
    set_membership.x<==attributes[1];
    set_membership.set<==set;
    set_membership_out<==set_membership.out;

    // verify the holder signature
    signal input challenge;
    signal input holder_pk[2];
    signal input holder_signature[3]; // Verifiable presentation signature
    component ecdsaH=EdDSAPoseidonVerifier();
    ecdsaH.enabled<==1;
    ecdsaH.Ax<==holder_pk[0];
    ecdsaH.Ay<==holder_pk[1];
    ecdsaH.R8x<==holder_signature[0];
    ecdsaH.R8y<==holder_signature[1];
    ecdsaH.S<==holder_signature[2];
    ecdsaH.M<==challenge;


// selective disclosure
    component mux[n_attr];

    issuer_id_out<==issuer_id;
    for (var i=0;i<n_attr;i++) {
        mux[i]=Mux1();
        mux[i].c[1]<==attributes[i];
        mux[i].c[0]<==0;
        mux[i].s<==expose_index[i];
        exposed_attributes[i]<==mux[i].out;
    }
}


component main = vp(4,5);