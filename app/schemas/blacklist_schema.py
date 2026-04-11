from .. import ma
from ..models.blacklist import BlacklistEmail


class BlacklistEmailSchema(ma.SQLAlchemyAutoSchema):
    class Meta:
        model = BlacklistEmail
        load_instance = True
        include_fk = True
