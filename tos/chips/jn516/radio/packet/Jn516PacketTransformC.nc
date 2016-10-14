configuration Jn516PacketTransformC {
	provides {
		interface Jn516PacketTransform;
	}
}
implementation {
	components Jn516PacketC,Jn516PacketTransformP;
	Jn516PacketTransform = Jn516PacketTransformP;
	Jn516PacketTransformP.Jn516PacketBody -> Jn516PacketC;
}
